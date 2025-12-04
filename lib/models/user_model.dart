class UserModel {
  String? firstName;
  String? lastName;
  String? username;
  String? phone;
  String? email;
  String? userId;
  int currentLevel;
  String difficulty;
  int unlockedLevel;

  UserModel({
    this.firstName,
    this.lastName,
    this.username,
    this.phone,
    this.email,
    this.userId,
    this.currentLevel = 1,
    this.difficulty = 'easy',
    this.unlockedLevel = 1,
  });

  // Factory to create from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      firstName: map['firstName'],
      lastName: map['lastName'],
      username: map['username'],
      phone: map['phone'],
      email: map['email'],
      userId: map['userId'],
      currentLevel: map['currentLevel'] ?? 1,
      difficulty: map['difficulty'] ?? 'easy',
      unlockedLevel: map['unlockedLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'phone': phone,
      'email': email,
      'userId': userId,
      'currentLevel': currentLevel,
      'difficulty': difficulty,
      'unlockedLevel': unlockedLevel,
    };
  }
}