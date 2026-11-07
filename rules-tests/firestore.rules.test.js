const { test, before, after, beforeEach, describe } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  arrayUnion,
  arrayRemove,
  increment,
  Timestamp,
} = require('firebase/firestore');

let env;

const student = (uid = 'student1') => ({
  uid,
  email: `${uid}@alustudent.com`,
  verified: true,
});
const staff = { uid: 'staff1', email: 'jordan@alueducation.com', verified: true };
const admin = { uid: 'admin1', email: 'b.niyigena@alustudent.com', verified: true };
const photo = 'https://res.cloudinary.com/dgxaazbuq/image/upload/v1/cir/incidents/a.jpg';

const change = (status, note) => ({
  status,
  updatedAt: serverTimestamp(),
  history: arrayUnion(event(status, note)),
});

function db(who) {
  if (!who) return env.unauthenticatedContext().firestore();
  return env
    .authenticatedContext(who.uid, {
      email: who.email,
      email_verified: who.verified,
    })
    .firestore();
}

function newIncident(uid = 'student1', overrides = {}) {
  return {
    title: 'Water leak',
    description: 'The tap in the second floor bathroom is leaking.',
    category: 'Water',
    building: 'Residence',
    status: 'Submitted',
    reporterId: uid,
    reporterName: 'Aline Student',
    isAnonymous: false,
    upvoteCount: 0,
    upvoters: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    history: [
      {
        status: 'Submitted',
        note: 'Report submitted',
        changedBy: 'Aline Student',
        at: Timestamp.now(),
      },
    ],
    ...overrides,
  };
}

function event(status, note = 'Looking into it') {
  return { status, note, changedBy: 'Jordan Staff', at: Timestamp.now() };
}

// Writes straight to the emulator without rules, to set up a starting state.
async function seed(id, overrides = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'incidents', id), {
      ...newIncident('student1'),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      ...overrides,
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-cir',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

after(async () => env.cleanup());

beforeEach(async () => env.clearFirestore());

describe('users', () => {
  const profile = (who, overrides = {}) => ({
    name: 'Aline Student',
    email: who.email,
    role: who.email.endsWith('@alueducation.com') ? 'staff' : 'student',
    campus: 'Kigali Campus',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  test('a new student can create their own profile before verifying', async () => {
    const me = { ...student(), verified: false };
    await assertSucceeds(setDoc(doc(db(me), 'users', me.uid), profile(me)));
  });

  test('a staff email gets the staff role on its own profile', async () => {
    await assertSucceeds(setDoc(doc(db(staff), 'users', staff.uid), profile(staff)));
  });

  test('a student cannot give themselves the staff role', async () => {
    const me = student();
    await assertFails(
      setDoc(doc(db(me), 'users', me.uid), profile(me, { role: 'staff' })),
    );
  });

  test('a staff email cannot be saved as a student', async () => {
    await assertFails(
      setDoc(doc(db(staff), 'users', staff.uid), profile(staff, { role: 'student' })),
    );
  });

  test('profiles cannot be created for another user', async () => {
    const me = student();
    await assertFails(setDoc(doc(db(me), 'users', 'someone-else'), profile(me)));
  });

  test('non ALU and look-alike emails are rejected', async () => {
    for (const email of [
      'eve@gmail.com',
      'eve@alueducation.com.evil.io',
      'eve@sub.alustudent.com',
    ]) {
      const eve = { uid: 'eve', email, verified: true };
      await assertFails(setDoc(doc(db(eve), 'users', 'eve'), profile(eve)));
    }
  });

  test('signed out visitors cannot write', async () => {
    await assertFails(
      setDoc(doc(db(null), 'users', 'x'), profile(student())),
    );
  });

  test('a student can rename themselves but not change role or email', async () => {
    const me = student();
    await assertSucceeds(setDoc(doc(db(me), 'users', me.uid), profile(me)));
    await assertSucceeds(updateDoc(doc(db(me), 'users', me.uid), { name: 'Aline N' }));
    await assertFails(updateDoc(doc(db(me), 'users', me.uid), { role: 'staff' }));
    await assertFails(
      updateDoc(doc(db(me), 'users', me.uid), { email: 'x@alueducation.com' }),
    );
  });

  test('students read only their own profile, staff read any', async () => {
    const a = student('a');
    const b = student('b');
    await assertSucceeds(setDoc(doc(db(a), 'users', 'a'), profile(a)));
    await assertSucceeds(getDoc(doc(db(a), 'users', 'a')));
    await assertFails(getDoc(doc(db(b), 'users', 'a')));
    await assertSucceeds(getDoc(doc(db(staff), 'users', 'a')));
  });

  test('profiles cannot be deleted', async () => {
    const me = student();
    await assertSucceeds(setDoc(doc(db(me), 'users', me.uid), profile(me)));
    await assertFails(deleteDoc(doc(db(me), 'users', me.uid)));
  });
});

describe('incident reads', () => {
  test('verified ALU users can read reports', async () => {
    await seed('r1');
    await assertSucceeds(getDoc(doc(db(student('other')), 'incidents', 'r1')));
    await assertSucceeds(getDoc(doc(db(staff), 'incidents', 'r1')));
  });

  test('unverified, signed out and outside users cannot', async () => {
    await seed('r1');
    await assertFails(
      getDoc(doc(db({ ...student('u'), verified: false }), 'incidents', 'r1')),
    );
    await assertFails(getDoc(doc(db(null), 'incidents', 'r1')));
    await assertFails(
      getDoc(
        doc(db({ uid: 'e', email: 'e@gmail.com', verified: true }), 'incidents', 'r1'),
      ),
    );
  });
});

describe('creating incidents', () => {
  test('a verified student can submit a valid report', async () => {
    const me = student();
    await assertSucceeds(setDoc(doc(db(me), 'incidents', 'n1'), newIncident(me.uid)));
  });

  test('a report with a Cloudinary photo url is allowed', async () => {
    const me = student();
    await assertSucceeds(
      setDoc(doc(db(me), 'incidents', 'n1'), newIncident(me.uid, { imageUrl: photo })),
    );
  });

  test('a photo url from anywhere else is refused', async () => {
    const me = student();
    for (const url of [
      'https://example.com/a.jpg',
      'https://res.cloudinary.com/someoneelse/image/upload/a.jpg',
      'http://res.cloudinary.com/dgxaazbuq/image/upload/a.jpg',
    ]) {
      await assertFails(
        setDoc(doc(db(me), 'incidents', 'n1'), newIncident(me.uid, { imageUrl: url })),
      );
    }
  });

  test('an anonymous report must not carry a name', async () => {
    const me = student();
    await assertSucceeds(
      setDoc(
        doc(db(me), 'incidents', 'n1'),
        newIncident(me.uid, { isAnonymous: true, reporterName: '' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db(me), 'incidents', 'n2'),
        newIncident(me.uid, { isAnonymous: true, reporterName: 'Aline Student' }),
      ),
    );
  });

  test('unverified students cannot submit', async () => {
    const me = { ...student(), verified: false };
    await assertFails(setDoc(doc(db(me), 'incidents', 'n1'), newIncident(me.uid)));
  });

  test('the reporter id must be the signed in user', async () => {
    await assertFails(
      setDoc(doc(db(student('a')), 'incidents', 'n1'), newIncident('b')),
    );
  });

  test('new reports must start as Submitted with no votes', async () => {
    const me = student();
    for (const bad of [
      { status: 'Resolved' },
      { upvoteCount: 5 },
      { upvoters: ['x'] },
    ]) {
      await assertFails(
        setDoc(doc(db(me), 'incidents', 'n1'), newIncident(me.uid, bad)),
      );
    }
  });

  test('field rules: lengths, category, building and extra fields', async () => {
    const me = student();
    for (const bad of [
      { title: 'Hey' },
      { title: 'a'.repeat(81) },
      { description: 'too short' },
      { description: 'a'.repeat(501) },
      { category: 'Parties' },
      { building: 'ab' },
      { building: 'b'.repeat(101) },
      { isAdmin: true },
    ]) {
      await assertFails(
        setDoc(doc(db(me), 'incidents', 'n1'), newIncident(me.uid, bad)),
      );
    }
  });

  test('createdAt has to be the server time', async () => {
    const me = student();
    await assertFails(
      setDoc(
        doc(db(me), 'incidents', 'n1'),
        newIncident(me.uid, { createdAt: Timestamp.fromDate(new Date('2020-01-01')) }),
      ),
    );
  });
});

describe('status updates', () => {
  test('staff can move a report forward and the history grows', async () => {
    await seed('r1');
    await assertSucceeds(
      updateDoc(doc(db(staff), 'incidents', 'r1'), change('In Progress')),
    );
  });

  test('students cannot change status, not even the author', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(student('student1')), 'incidents', 'r1'), change('Resolved')),
    );
    await assertFails(
      updateDoc(doc(db(student('other')), 'incidents', 'r1'), change('Resolved')),
    );
  });

  test('an unverified staff address is treated like any outsider', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(
        doc(db({ ...staff, verified: false }), 'incidents', 'r1'),
        change('Resolved'),
      ),
    );
  });

  test('rejecting needs a note', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(staff), 'incidents', 'r1'), change('Rejected', '')),
    );
    await assertSucceeds(
      updateDoc(doc(db(staff), 'incidents', 'r1'), change('Rejected', 'Duplicate')),
    );
  });

  test('unknown statuses are refused', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(staff), 'incidents', 'r1'), change('Escalated')),
    );
  });

  test('staff cannot rewrite the history or edit other fields', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(staff), 'incidents', 'r1'), {
        status: 'Resolved',
        updatedAt: serverTimestamp(),
        history: [event('Resolved')],
      }),
    );
    await assertFails(
      updateDoc(doc(db(staff), 'incidents', 'r1'), {
        ...change('Resolved'),
        title: 'Changed by staff',
      }),
    );
    await assertFails(
      updateDoc(doc(db(staff), 'incidents', 'r1'), { reporterId: 'staff1' }),
    );
  });

  test('the new history entry has to match the new status', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(staff), 'incidents', 'r1'), {
        status: 'Resolved',
        updatedAt: serverTimestamp(),
        history: arrayUnion(event('In Progress')),
      }),
    );
  });
});

describe('upvotes', () => {
  const vote = (uid) => ({
    upvoters: arrayUnion(uid),
    upvoteCount: increment(1),
  });

  test('a student can upvote someone else\'s report once', async () => {
    await seed('r1');
    const me = student('voter');
    await assertSucceeds(updateDoc(doc(db(me), 'incidents', 'r1'), vote('voter')));
  });

  test('the same student cannot vote twice', async () => {
    await seed('r1', { upvoters: ['voter'], upvoteCount: 1 });
    await assertFails(
      updateDoc(doc(db(student('voter')), 'incidents', 'r1'), {
        upvoters: arrayUnion('voter'),
        upvoteCount: increment(1),
      }),
    );
  });

  test('the author cannot upvote their own report', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(student('student1')), 'incidents', 'r1'), vote('student1')),
    );
  });

  test('a vote cannot be cast in someone else\'s name', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(student('voter')), 'incidents', 'r1'), vote('other')),
    );
  });

  test('the counter has to match the list', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(student('voter')), 'incidents', 'r1'), {
        upvoters: arrayUnion('voter'),
        upvoteCount: increment(10),
      }),
    );
  });

  test('a student can take back their own vote but not remove another', async () => {
    await seed('r1', { upvoters: ['voter', 'friend'], upvoteCount: 2 });
    await assertFails(
      updateDoc(doc(db(student('voter')), 'incidents', 'r1'), {
        upvoters: arrayRemove('friend'),
        upvoteCount: increment(-1),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db(student('voter')), 'incidents', 'r1'), {
        upvoters: arrayRemove('voter'),
        upvoteCount: increment(-1),
      }),
    );
  });

  test('voting cannot be used to edit anything else', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db(student('voter')), 'incidents', 'r1'), {
        ...vote('voter'),
        status: 'Resolved',
      }),
    );
  });
});

describe('deleting incidents', () => {
  test('the author can delete while the report is still Submitted', async () => {
    await seed('r1');
    await assertSucceeds(deleteDoc(doc(db(student('student1')), 'incidents', 'r1')));
  });

  test('the author cannot delete once staff are working on it', async () => {
    await seed('r1', { status: 'In Progress' });
    await assertFails(deleteDoc(doc(db(student('student1')), 'incidents', 'r1')));
  });

  test('other students cannot delete', async () => {
    await seed('r1');
    await assertFails(deleteDoc(doc(db(student('other')), 'incidents', 'r1')));
  });

  test('staff can delete', async () => {
    await seed('r1', { status: 'Resolved' });
    await assertSucceeds(deleteDoc(doc(db(staff), 'incidents', 'r1')));
  });
});

describe('alert states', () => {
  const state = (overrides = {}) => ({
    read: true,
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('a verified person keeps their own read and deleted marks', async () => {
    const me = student();
    const ref = doc(db(me), 'users', me.uid, 'alertStates', 'r1:2');
    await assertSucceeds(setDoc(ref, state()));
    await assertSucceeds(setDoc(ref, state({ deleted: true }), { merge: true }));
    await assertSucceeds(getDoc(ref));
  });

  test('nobody else can read or write them', async () => {
    const me = student();
    await assertSucceeds(
      setDoc(doc(db(me), 'users', me.uid, 'alertStates', 'r1:2'), state()),
    );
    const other = student('other');
    await assertFails(getDoc(doc(db(other), 'users', me.uid, 'alertStates', 'r1:2')));
    await assertFails(
      setDoc(doc(db(other), 'users', me.uid, 'alertStates', 'r1:3'), state()),
    );
    await assertFails(getDoc(doc(db(staff), 'users', me.uid, 'alertStates', 'r1:2')));
  });

  test('only the expected fields and types are allowed', async () => {
    const me = student();
    const ref = doc(db(me), 'users', me.uid, 'alertStates', 'r1:2');
    await assertFails(setDoc(ref, state({ title: 'sneaky' })));
    await assertFails(setDoc(ref, state({ read: 'yes' })));
    await assertFails(setDoc(ref, { read: true, updatedAt: Timestamp.now() }));
    await assertFails(
      setDoc(doc(db({ ...me, verified: false }), 'users', me.uid, 'alertStates', 'x'), state()),
    );
  });
});

describe('saving a profile from the app', () => {
  const existing = {
    name: 'Aline Student',
    email: 'student1@alustudent.com',
    role: 'student',
    campus: 'Kigali Campus',
  };
  const photo = 'https://res.cloudinary.com/dgxaazbuq/image/upload/v1/cir/profiles/a.jpg';

  async function seedProfile(data = existing) {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', 'student1'), data);
    });
  }
  const ref = () => doc(db(student()), 'users', 'student1');

  test('name, campus and photo can be saved together', async () => {
    await seedProfile();
    await assertSucceeds(
      updateDoc(ref(), { name: 'Aline N', campus: 'Mauritius Campus', photoUrl: photo }),
    );
  });

  test('each field can be saved on its own', async () => {
    await seedProfile();
    await assertSucceeds(updateDoc(ref(), { campus: 'Mauritius Campus' }));
    await assertSucceeds(updateDoc(ref(), { photoUrl: photo }));
    await assertSucceeds(updateDoc(ref(), { name: 'Aline Niyonsenga' }));
  });

  test('an older profile without a campus can get one', async () => {
    await seedProfile({ name: 'Aline', email: 'student1@alustudent.com', role: 'student' });
    await assertSucceeds(updateDoc(ref(), { campus: 'Kigali Campus' }));
  });

  test('a photo that is not on our Cloudinary is refused', async () => {
    await seedProfile();
    await assertFails(updateDoc(ref(), { photoUrl: 'https://example.com/a.jpg' }));
  });

  test('a missing profile can be created with the allowed fields', async () => {
    await assertSucceeds(
      setDoc(ref(), {
        name: 'Aline N',
        email: 'student1@alustudent.com',
        role: 'student',
        campus: 'Kigali Campus',
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('role and email can never be changed', async () => {
    await seedProfile();
    await assertFails(updateDoc(ref(), { role: 'staff' }));
    await assertFails(updateDoc(ref(), { email: 'x@alustudent.com' }));
  });
});

describe('the admin account', () => {
  test('keeps the student role on its own profile', async () => {
    const profileFor = (role) => ({
      name: 'Admin Student',
      email: admin.email,
      role,
      campus: 'Kigali Campus',
      createdAt: serverTimestamp(),
    });
    await assertFails(setDoc(doc(db(admin), 'users', admin.uid), profileFor('staff')));
    await assertSucceeds(setDoc(doc(db(admin), 'users', admin.uid), profileFor('student')));
  });

  test('can move a report forward like staff', async () => {
    await seed('r1');
    await assertSucceeds(updateDoc(doc(db(admin), 'incidents', 'r1'), change('In Progress')));
  });

  test('can manage campus facilities', async () => {
    await assertSucceeds(
      setDoc(doc(db(admin), 'campusFacilities', 'Kigali Campus', 'facilities', 'lib'), {
        name: 'Library',
        areas: ['Study area'],
      }),
    );
  });

  test('an unverified admin address gets nothing extra', async () => {
    await seed('r1');
    await assertFails(
      updateDoc(doc(db({ ...admin, verified: false }), 'incidents', 'r1'), change('In Progress')),
    );
  });

  test('other student addresses stay students', async () => {
    await seed('r1');
    await assertFails(updateDoc(doc(db(student('other')), 'incidents', 'r1'), change('In Progress')));
    await assertFails(
      updateDoc(
        doc(db({ uid: 'x', email: 'b.niyigena@gmail.com', verified: true }), 'incidents', 'r1'),
        change('In Progress'),
      ),
    );
  });
});

describe('everything else', () => {
  test('unknown collections are closed', async () => {
    await assertFails(getDoc(doc(db(staff), 'secrets', 'x')));
    await assertFails(setDoc(doc(db(staff), 'secrets', 'x'), { a: 1 }));
  });
});
