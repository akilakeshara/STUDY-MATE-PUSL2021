const admin = require('firebase-admin');

// Keep this admin account
const ADMIN_EMAIL = 'admin@studymate.com';

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    'Set GOOGLE_APPLICATION_CREDENTIALS to your service-account JSON path before running this script.',
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const deleteAllUsersExceptAdmin = async (nextPageToken) => {
  const result = await admin.auth().listUsers(1000, nextPageToken);

  const usersToDelete = result.users.filter(
    (user) => (user.email || '').toLowerCase() !== ADMIN_EMAIL.toLowerCase(),
  );

  const uids = usersToDelete.map((user) => user.uid);

  if (uids.length > 0) {
    const deleteResult = await admin.auth().deleteUsers(uids);
    console.log(
      `Deleted ${deleteResult.successCount} users, failed ${deleteResult.failureCount}`,
    );

    if (deleteResult.errors.length > 0) {
      console.log('Delete errors:', deleteResult.errors);
    }
  }

  if (result.pageToken) {
    await deleteAllUsersExceptAdmin(result.pageToken);
  }
};

deleteAllUsersExceptAdmin()
  .then(() => {
    console.log('Finished deleting all users except admin.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error deleting users:', error);
    process.exit(1);
  });
