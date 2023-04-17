import 'package:flutter/scheduler.dart';
import 'package:signup_login/screens/appointment_patient.dart';
import 'package:signup_login/screens/clinicCard.dart';
import 'package:signup_login/screens/docCard.dart';
import 'package:signup_login/screens/appointmentCard.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signup_login/screens/doctor_page.dart';
import 'package:signup_login/screens/login_screen.dart';
import 'package:signup_login/services/auth.dart';
import 'package:signup_login/services/database.dart';

class DoctorDetails {
  String documentId;
  String designation;
  String name;
  String qualification;

  DoctorDetails(
      {required this.documentId,
      required this.designation,
      required this.name,
      required this.qualification});
}

class AppointmentDetails {
  dynamic slotBooked;
  dynamic doctorUid;
  dynamic sessionTime;
  dynamic consultationFee;
  dynamic timeOfBooking;
  dynamic bookingStatus;
  dynamic date;

  AppointmentDetails({
    required this.slotBooked,
    required this.doctorUid,
    required this.sessionTime,
    required this.consultationFee,
    required this.bookingStatus,
    required this.timeOfBooking,
    required this.date,
  });
}

class PatientHome extends StatefulWidget {
  const PatientHome({Key? key}) : super(key: key);

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  late Future<void> _future;

  late DatabaseService _database;

  AuthService _auth = AuthService();
  String? uid;
  dynamic patientName = null;
  List<DoctorDetails> doctorDetailsList = [];
  List<AppointmentDetails> appointmentDetailsList = [];
  Future<void> _retrieveAppointmentDetails() async {
    var appointmentsCollection = FirebaseFirestore.instance
        .collection("appointments")
        .where("status", isEqualTo: "Booked");
    var appointmentQuerySnapshot = await appointmentsCollection.get();
    dynamic slotBooked = {};
    dynamic doctorUid = "";
    dynamic consultationFee = "";
    dynamic sessionTime = "";
    dynamic timeOfBooking;
    dynamic bookingStatus;
    var appointmentDetails;
    appointmentDetailsList = [];
    if (appointmentQuerySnapshot.docs.isNotEmpty) {
      // print(appointmentQuerySnapshot.docs.elementAt(0)["doctorUid"]);
      print("HERE HERE");
      // Iterate over the list of documents and get the document ID for each one
      // var docId = docSnapshot.id;
      // if (docId != "doctor") {
      appointmentDetails = appointmentQuerySnapshot.docs
          .where((doc) => doc.id != "doctors")
          .map((doc) => AppointmentDetails(
                slotBooked: doc['slotChosen'],
                consultationFee: doc['consultationFee'],
                sessionTime: doc['sessionTime'],
                bookingStatus: doc['status'],
                timeOfBooking: doc['timeOfBooking'],
                doctorUid: doc['doctorUid'],
                date: doc['date'],
              ))
          .toList();

      print(appointmentDetails);
      print(appointmentDetails);
      appointmentDetailsList
          .addAll(appointmentDetails.cast<AppointmentDetails>());

      print("Appointment List");
      print(appointmentDetailsList);
    } else {
      print('No documents found in the appointments collection.');
    }

    // do like get todays day and show his timings and only list if available in this time, if not available dont add in the list.
  }

  Future<void> _retrieveDoctorDetails() async {
    var clinicsCollection = FirebaseFirestore.instance
        .collection("users")
        .where("userType", isEqualTo: "clinic");
    var clinicsQuerySnapshot = await clinicsCollection.get();
    DocumentSnapshot<Map<String, dynamic>> docSnapshot;
    var documentRef;
    var doctorsCollection;
    dynamic name = "";
    dynamic phone = "";
    dynamic category = "";
    dynamic qualification = "";
    dynamic timings =
        ""; // do like get todays day and show his timings and only list if available in this time, if not available dont add in the list.
    dynamic uid = "";
    doctorDetailsList = [];

    for (final clinic in clinicsQuerySnapshot.docs) {
      // print(clinic.id);
      doctorsCollection = clinic.reference.collection("doctors");
      final snapshot = await doctorsCollection.get();
      if (snapshot.docs.isNotEmpty) {
        // timings = snapshot.docs['timings'];
        print(timings);
        print(snapshot.docs.length);
        print("Entered Clinic");
        print(clinic.id);

        final doctorDetails = snapshot.docs
            .map((doc) => DoctorDetails(
                  documentId: doc.id,
                  designation: doc['category'],
                  name: doc['name'],
                  qualification: doc['qualification'],
                ))
            .toList();

        doctorDetailsList.addAll(doctorDetails.cast<DoctorDetails>());
      }
    }
  }

  Future<dynamic> getPatientName() {
    uid = _auth.getCurrentUserUid();
    _database = DatabaseService(uid: uid);
    setState(() {
      patientName = _database.getPatientName(uid!);
    });
    print(patientName);
    return patientName;
  }

  Position? userposition;
  String? useraddress;
  double? lat, long;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      Geolocator.openLocationSettings();
      return Future.error("Location Services not enabled");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission not granted!!!");
        return false;
      } else {
        return true;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            userposition!.latitude, userposition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        useraddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      print(e);
    });
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        userposition = position;
        lat = position.latitude;
        long = position.longitude;
      });
      _getAddressFromLatLng(userposition!);
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _future = _retrieveAppointmentDetails();
    print(lat);
    print(long);
  }

  final usersCollectionReference =
      FirebaseFirestore.instance.collection('users');
  // Stream<Map<String, dynamic>> getPatientData() async* {

  //   DocumentSnapshot documentSnapshot =
  //       await usersCollectionReference.doc(uid!).get();
  //   Map<String, dynamic> documentData = {};
  //   if (documentSnapshot.exists) {
  //     documentData = documentSnapshot.data() as Map<String, dynamic>;
  //     print(documentData);
  //     yield documentData;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // final String name = "deepak";
    doctorDetailsList = [];
    String? uid = _auth.getCurrentUserUid();
    print("uid" + uid!);

    print(doctorDetailsList);
    print(doctorDetailsList.length);
    print(appointmentDetailsList.length);
    // _auth.signOut();
    // Navigator.of(context).pushReplacement(new MaterialPageRoute(
    //     builder: (BuildContext context) => LoginScreen()));

    return FutureBuilder(
        future: usersCollectionReference.doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var name = snapshot.data!['name'];
            print(name);
            return Material(
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Greetings ${name}!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.pin_drop_rounded,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Guindy,",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text("Chennai")
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),

                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 5.0),
                        padding: EdgeInsets.fromLTRB(5, 10, 5, 5),
                        decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            borderRadius: BorderRadius.circular(50)),
                        child: SizedBox(
                          height: 30.0,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  "Search for doctors and clinics near you",
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search),
                              prefixIconColor: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 125,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {},
                              child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xff6c59b0),
                                      Color(0xffa9a2f7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(2.0, 5.0),
                                      blurRadius: 10.0,
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // CircleAvatar(
                                    //   radius: 28,
                                    //   backgroundColor: Colors.white,
                                    //   backgroundImage: AssetImage(
                                    //       "assets/Images/clinicIcon.png"),
                                    // ),
                                    Column(
                                      children: [
                                        Text(
                                          "Clinic Visit",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Book an appointment",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xffaf4844),
                                      Color(0xff733734),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(2.0, 5.0),
                                      blurRadius: 10.0,
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // CircleAvatar(
                                    //   radius: 28,
                                    //   backgroundColor: Colors.white,
                                    //   backgroundImage: AssetImage(
                                    //       "assets/Images/danger.png"),
                                    // ),
                                    Column(
                                      children: [
                                        Text(
                                          "Emergency",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Call an ambulance",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 30.0,
                      ),

                      // Doctors listview
                      Container(
                        padding: EdgeInsets.only(left: 25.0),
                        child: Text(
                          "Popular Doctors near you",
                          style: TextStyle(
                              fontSize: 22.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      FutureBuilder<void>(
                        future: _retrieveDoctorDetails(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            print(snapshot.error);
                            return const Text('Error');
                          } else {
                            print(doctorDetailsList.length);
                            return Container(
                              height: 140.0,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: doctorDetailsList.length,
                                itemBuilder: (context, index) {
                                  final doctorDetails =
                                      doctorDetailsList[index];
                                  return InkWell(
                                    child: DocCard(
                                      designation: doctorDetails.designation,
                                      name: doctorDetails.name,
                                      qualification:
                                          doctorDetails.qualification,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => DoctorPage(
                                                  DoctorUid:
                                                      doctorDetails.documentId,
                                                )),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                      // Container(
                      //   height: 140.0,
                      //   child: ListView.builder(
                      //     scrollDirection: Axis.horizontal,
                      //     itemCount: doctorDetailsList.length,
                      //     itemBuilder: (context, index) {
                      //       final doctorDetails = doctorDetailsList[index];
                      //       return DocCard(
                      //         designation: doctorDetails.designation,
                      //         name: doctorDetails.name,
                      //         qualification: doctorDetails.qualification,
                      //       );
                      //     },
                      //   ),
                      // ),
                      SizedBox(
                        height: 30.0,
                      ),

                      // Clinics listview

                      Container(
                        padding: EdgeInsets.only(left: 25.0),
                        child: Text(
                          "Popular Clinics near you",
                          style: TextStyle(
                              fontSize: 22.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      Container(
                        height: 140.0,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ClinicCard(
                              name: "ABC Clinic",
                              rating: "4.3",
                            ),
                            ClinicCard(
                              name: "PQR Clinic",
                              rating: "4.1",
                            ),
                            ClinicCard(name: "Apollo 24x7", rating: "4.5")
                          ],
                        ),
                      ),

                      //Appointment List View
                      SizedBox(height: 30.0),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Your Active Appointments",
                              style: TextStyle(
                                  fontSize: 22.0, fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _future = _retrieveAppointmentDetails();
                                  });
                                },
                                child: const Text('Reload'),
                              ),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.only(left: 25.0),
                      ), //Either Status is Booked or status is
                      SizedBox(
                        height: 15,
                      ),
                      FutureBuilder<void>(
                        future: _retrieveAppointmentDetails(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}");
                          } else {
                            print("APPOINTMENT");
                            print(appointmentDetailsList.length);
                            print(appointmentDetailsList);
                            return Container(
                              height: 140.0,
                              child: ListView.builder(
                                // physics: NeverScrollableScrollPhysics(),
                                // scrollDirection: Axis.vertical,
                                itemCount: appointmentDetailsList.length,
                                itemBuilder: (context, index) {
                                  print("INDEX");
                                  print(index);
                                  final appointmentDetails =
                                      appointmentDetailsList[index];
                                  return InkWell(
                                    child: AppointmentCard(
                                      doctorName: appointmentDetails.doctorUid,
                                      slotTime: appointmentDetails.slotBooked,
                                      sessionTime:
                                          appointmentDetails.sessionTime,
                                      consultationFee:
                                          appointmentDetails.consultationFee,
                                      date: appointmentDetails.date,
                                    ),
                                    onTap: () {
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //       builder: (context) => DoctorPage(
                                      //             DoctorUid:
                                      //                 doctorDetails.documentId,
                                      //           )),
                                      // );
                                    },
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            print("${snapshot.error}");

            return Text("/nerror:  ${snapshot.error}");
          }
        });
  }
}
