const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, Timestamp } = require("firebase/firestore");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "caren-app-test";

describe("CAREN Firestore Security Rules - Emulator Verification", () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(__dirname, "../../firestore.rules");
    const rules = fs.readFileSync(rulesPath, "utf8");

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: "127.0.0.1",
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();

    // Seed baseline data using admin context (unrestricted)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Seed family circle with Alice (owner/creator) and Bob (member)
      await setDoc(doc(db, "families", "fam_1"), {
        name: "Vance Family",
        createdBy: "alice_uid",
        memberUids: ["alice_uid", "bob_uid"],
        createdAt: Timestamp.now(),
      });

      // Seed Alice member record (owner)
      await setDoc(doc(db, "families", "fam_1", "members", "alice_uid"), {
        name: "Alice Vance",
        email: "alice@example.com",
        relationship: "Mother",
        role: "owner",
        joinedAt: Timestamp.now(),
        sharingPermission: {
          shareCheckInStatus: true,
          shareSelfReportedMood: true,
          shareVitalsMeasurements: true,
          shareNotes: true,
        },
      });

      // Seed Bob member record (regular member)
      await setDoc(doc(db, "families", "fam_1", "members", "bob_uid"), {
        name: "Bob Vance",
        email: "bob@example.com",
        relationship: "Son",
        role: "member",
        joinedAt: Timestamp.now(),
        sharingPermission: {
          shareCheckInStatus: true,
          shareSelfReportedMood: true,
          shareVitalsMeasurements: false,
          shareNotes: false,
        },
      });

      // Seed Bob's daily check-in
      await setDoc(doc(db, "families", "fam_1", "checkins", "chk_bob_1"), {
        userId: "bob_uid",
        userName: "Bob Vance",
        timestamp: Timestamp.now(),
        feeling: "doingFine",
        sleep: "restful",
        tookPrescribedMedications: true,
        isSharedWithFamily: true,
      });

      // Seed Bob's private Me session (strictly personal sanctuary)
      await setDoc(doc(db, "users", "bob_uid", "me_sessions", "me_session_1"), {
        activityType: "breathing",
        durationSeconds: 300,
        reflectionNotes: "Feeling calm after deep breathing.",
        timestamp: Timestamp.now(),
      });

      // Seed pending invitation for Charlie
      const sevenDaysLater = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      await setDoc(doc(db, "invitations", "inv_charlie"), {
        familyId: "fam_1",
        familyName: "Vance Family",
        invitedByUid: "alice_uid",
        invitedByEmail: "alice@example.com",
        inviteeEmail: "charlie@example.com",
        relationship: "Brother",
        status: "pending",
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(sevenDaysLater),
      });

      // Seed expired invitation for Dave
      const eightDaysAgo = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000);
      const oneDayAgo = new Date(Date.now() - 1 * 24 * 60 * 60 * 1000);
      await setDoc(doc(db, "invitations", "inv_expired_dave"), {
        familyId: "fam_1",
        familyName: "Vance Family",
        invitedByUid: "alice_uid",
        invitedByEmail: "alice@example.com",
        inviteeEmail: "dave@example.com",
        relationship: "Cousin",
        status: "pending",
        createdAt: Timestamp.fromDate(eightDaysAgo),
        expiresAt: Timestamp.fromDate(oneDayAgo),
      });

      // Seed already accepted invitation for Eve
      await setDoc(doc(db, "invitations", "inv_accepted_eve"), {
        familyId: "fam_1",
        familyName: "Vance Family",
        invitedByUid: "alice_uid",
        invitedByEmail: "alice@example.com",
        inviteeEmail: "eve@example.com",
        relationship: "Sister",
        status: "accepted",
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(sevenDaysLater),
      });

      // Seed revoked invitation for Frank
      await setDoc(doc(db, "invitations", "inv_revoked_frank"), {
        familyId: "fam_1",
        familyName: "Vance Family",
        invitedByUid: "alice_uid",
        invitedByEmail: "alice@example.com",
        inviteeEmail: "frank@example.com",
        relationship: "Friend",
        status: "revoked",
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(sevenDaysLater),
      });
    });
  });

  // --- 1. Family Access & Membership ---
  it("Non-members cannot read family documents", async () => {
    const intruderDb = testEnv.authenticatedContext("intruder_uid", {
      email: "intruder@example.com",
    }).firestore();

    await assertFails(getDoc(doc(intruderDb, "families", "fam_1")));
  });

  it("Non-members cannot read family check-ins", async () => {
    const intruderDb = testEnv.authenticatedContext("intruder_uid", {
      email: "intruder@example.com",
    }).firestore();

    await assertFails(getDoc(doc(intruderDb, "families", "fam_1", "checkins", "chk_bob_1")));
  });

  it("Users cannot add themselves directly to a family without authorization", async () => {
    const strangerDb = testEnv.authenticatedContext("stranger_uid", {
      email: "stranger@example.com",
    }).firestore();

    // Attempt to inject member record directly into fam_1
    await assertFails(
      setDoc(doc(strangerDb, "families", "fam_1", "members", "stranger_uid"), {
        name: "Stranger Danger",
        email: "stranger@example.com",
        role: "admin",
        joinedAt: Timestamp.now(),
      })
    );
  });

  it("Members cannot promote themselves to admin or owner", async () => {
    const bobDb = testEnv.authenticatedContext("bob_uid", {
      email: "bob@example.com",
    }).firestore();

    // Bob is a member and attempts to promote himself to admin
    await assertFails(
      updateDoc(doc(bobDb, "families", "fam_1", "members", "bob_uid"), {
        role: "admin",
      })
    );
  });

  it("Members cannot alter another member's sharing permissions", async () => {
    // Alice is circle owner/admin, but cannot alter Bob's privacy consent
    const aliceDb = testEnv.authenticatedContext("alice_uid", {
      email: "alice@example.com",
    }).firestore();

    await assertFails(
      updateDoc(doc(aliceDb, "families", "fam_1", "members", "bob_uid"), {
        sharingPermission: {
          shareCheckInStatus: true,
          shareSelfReportedMood: true,
          shareVitalsMeasurements: true,
          shareNotes: true,
        },
      })
    );
  });

  it("A member can successfully update their own sharing permissions", async () => {
    const bobDb = testEnv.authenticatedContext("bob_uid", {
      email: "bob@example.com",
    }).firestore();

    await assertSucceeds(
      updateDoc(doc(bobDb, "families", "fam_1", "members", "bob_uid"), {
        sharingPermission: {
          shareCheckInStatus: true,
          shareSelfReportedMood: true,
          shareVitalsMeasurements: true,
          shareNotes: false,
        },
      })
    );
  });

  // --- 2. Invitation Integrity & Anti-Forgery ---
  it("Invitations cannot be forged on behalf of another user", async () => {
    const malloryDb = testEnv.authenticatedContext("mallory_uid", {
      email: "mallory@example.com",
    }).firestore();

    // Mallory tries to send an invite claiming Alice sent it
    await assertFails(
      setDoc(doc(malloryDb, "invitations", "inv_forged"), {
        familyId: "fam_1",
        familyName: "Vance Family",
        invitedByUid: "alice_uid", // Claiming Alice's identity
        invitedByEmail: "alice@example.com",
        inviteeEmail: "victim@example.com",
        relationship: "Guest",
        status: "pending",
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(new Date(Date.now() + 7 * 86400000)),
      })
    );
  });

  it("Expired and revoked invitations cannot be accepted", async () => {
    // Dave tries to accept expired invite
    const daveDb = testEnv.authenticatedContext("dave_uid", {
      email: "dave@example.com",
    }).firestore();

    await assertFails(
      updateDoc(doc(daveDb, "invitations", "inv_expired_dave"), {
        status: "accepted",
      })
    );

    // Frank tries to accept revoked invite
    const frankDb = testEnv.authenticatedContext("frank_uid", {
      email: "frank@example.com",
    }).firestore();

    await assertFails(
      updateDoc(doc(frankDb, "invitations", "inv_revoked_frank"), {
        status: "accepted",
      })
    );
  });

  it("Accepted invitations cannot be reused", async () => {
    const eveDb = testEnv.authenticatedContext("eve_uid", {
      email: "eve@example.com",
    }).firestore();

    // Attempting to re-accept an already accepted invitation
    await assertFails(
      updateDoc(doc(eveDb, "invitations", "inv_accepted_eve"), {
        status: "accepted",
      })
    );
  });

  it("An invite cannot be accepted by an unrelated authenticated account", async () => {
    // Oscar tries to accept Charlie's invitation
    const oscarDb = testEnv.authenticatedContext("oscar_uid", {
      email: "oscar@example.com", // Not charlie@example.com
    }).firestore();

    await assertFails(
      updateDoc(doc(oscarDb, "invitations", "inv_charlie"), {
        status: "accepted",
      })
    );
  });

  it("Intended invitee with matching verified email can accept pending invitation", async () => {
    const charlieDb = testEnv.authenticatedContext("charlie_uid", {
      email: "charlie@example.com",
    }).firestore();

    await assertSucceeds(
      updateDoc(doc(charlieDb, "invitations", "inv_charlie"), {
        status: "accepted",
      })
    );
  });

  // --- 3. Removed Member Loss of Access ---
  it("A removed member immediately loses family access", async () => {
    // First verify Bob can read the family while in memberUids
    const bobDb = testEnv.authenticatedContext("bob_uid", {
      email: "bob@example.com",
    }).firestore();

    await assertSucceeds(getDoc(doc(bobDb, "families", "fam_1")));

    // Admin/Creator removes Bob from memberUids
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await updateDoc(doc(db, "families", "fam_1"), {
        memberUids: ["alice_uid"], // Bob removed
      });
      await deleteDoc(doc(db, "families", "fam_1", "members", "bob_uid"));
    });

    // Bob now immediately loses read access
    await assertFails(getDoc(doc(bobDb, "families", "fam_1")));
    await assertFails(getDoc(doc(bobDb, "families", "fam_1", "checkins", "chk_bob_1")));
  });

  // --- 4. Check-in Modification Protection ---
  it("Users cannot modify another user's check-ins", async () => {
    const aliceDb = testEnv.authenticatedContext("alice_uid", {
      email: "alice@example.com",
    }).firestore();

    // Alice attempts to alter Bob's check-in
    await assertFails(
      updateDoc(doc(aliceDb, "families", "fam_1", "checkins", "chk_bob_1"), {
        feeling: "restingToday",
      })
    );

    // Bob can modify his own check-in
    const bobDb = testEnv.authenticatedContext("bob_uid", {
      email: "bob@example.com",
    }).firestore();

    await assertSucceeds(
      updateDoc(doc(bobDb, "families", "fam_1", "checkins", "chk_bob_1"), {
        feeling: "feelingWell",
      })
    );
  });

  // --- 5. Privacy Sanctuary: Private Me Sessions ---
  it("Family members cannot read private Me sessions", async () => {
    const aliceDb = testEnv.authenticatedContext("alice_uid", {
      email: "alice@example.com",
    }).firestore();

    // Alice (family member & owner) tries to read Bob's private Me sanctuary
    await assertFails(
      getDoc(doc(aliceDb, "users", "bob_uid", "me_sessions", "me_session_1"))
    );

    // Bob (the owner) can read his own private Me sanctuary
    const bobDb = testEnv.authenticatedContext("bob_uid", {
      email: "bob@example.com",
    }).firestore();

    await assertSucceeds(
      getDoc(doc(bobDb, "users", "bob_uid", "me_sessions", "me_session_1"))
    );
  });

  it("Family administrators cannot access private wellness records or trends", async () => {
    const aliceDb = testEnv.authenticatedContext("alice_uid", {
      email: "alice@example.com",
    }).firestore();

    // Administrator attempting to query Bob's personal settings or trends
    await assertFails(
      getDoc(doc(aliceDb, "users", "bob_uid", "personal_trends", "trend_1"))
    );
  });
});

