const campusAreas = <String, Map<String, List<String>>>{
  'Kigali Campus': {
    'Classrooms': [
      'Room 101',
      'Room 102',
      'Room 201',
      'Room 204',
      'Lecture Hall 1',
    ],
    'Library': ['Study area', 'Group rooms', 'Computer area', 'Restrooms'],
    'Cafeteria': ['Kitchen', 'Dining area', 'Serving area', 'Restrooms'],
    'Residence': [
      'Residence rooms',
      'Residence cafeteria',
      'Residence electricity',
      'Showers',
      'Common room',
    ],
    'Campus facilities': [
      'Main entrance',
      'Hallways',
      'Campus electricity',
      'Campus water',
      'Outdoor areas',
    ],
  },
  'Mauritius Campus': {
    'Classrooms': ['Room 101', 'Room 102', 'Room 201', 'Lecture Hall'],
    'Library': ['Study area', 'Group rooms', 'Computer area'],
    'Cafeteria': ['Kitchen', 'Dining area', 'Serving area'],
    'Residence': [
      'Residence rooms',
      'Residence cafeteria',
      'Residence electricity',
      'Showers',
      'Common room',
    ],
    'Campus facilities': [
      'Main entrance',
      'Hallways',
      'Campus electricity',
      'Campus water',
      'Outdoor areas',
    ],
  },
};

String defaultFacilityId(String name) =>
    'default_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
