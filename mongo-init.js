// Create application database and user
db = db.getSiblingDB('global_radio');

// Create application user with restricted permissions
db.createUser({
  user: 'app_user',
  pwd: 'changeme',
  roles: [
    {
      role: 'readWrite',
      db: 'global_radio'
    }
  ]
});

// Create collections with validation
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['username', 'email', 'created_at'],
      properties: {
        username: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        email: {
          bsonType: 'string',
          pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$',
          description: 'must be a valid email address and is required'
        },
        created_at: {
          bsonType: 'date',
          description: 'must be a date and is required'
        }
      }
    }
  }
});

// Create indexes
db.users.createIndex({ 'email': 1 }, { unique: true });
db.users.createIndex({ 'username': 1 }, { unique: true });

// Create other collections
db.createCollection('stations');
db.createCollection('playlists');
db.createCollection('favorites');

// Create indexes for other collections
db.stations.createIndex({ 'name': 1 }, { unique: true });
db.playlists.createIndex({ 'user_id': 1 });
db.favorites.createIndex({ 'user_id': 1, 'station_id': 1 }, { unique: true }); 