import 'package:allogroup/screens/office/notifications/notifications.dart';
import 'package:allogroup/screens/office/user/profil/profilScreen.dart';
// import 'package:allogroup/screens/office/widgets/dimensions.dart';
import 'package:flutter/material.dart';
import 'screens/office/components/header.dart';
import 'screens/office/components/accueilservices.dart';
import 'screens/office/components/carousel_accueil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool homeButtonSelected = true; // Par défaut, "Home" est inactif
  bool notifButtonSelected = false; // Par défaut, "food" est actif
  bool profilButtonSelected = false; // "Delivery" est inactif
  int numberOfPromotions = 0;

  @override
  void initState() {
    super.initState();
    // Appeler la fonction pour récupérer la taille des promotions lors de l'initialisation du widget
    fetchPromotionsSize();
  }

  Future<void> fetchPromotionsSize() async {
    int size = await getSizeOfPromotions();
    setState(() {
      numberOfPromotions = size;
    });
  }

  Future<int> getSizeOfPromotions() async {
    try {
      // Accès au document 'zone' dans la collection 'administrateur'
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('administrateur')
          .doc('admin')
          .get();

      if (adminSnapshot.exists) {
        // Vérification de l'existence de la clé 'promotions'
        Map<String, dynamic>? data =
            adminSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('promotion')) {
          List<dynamic> promotions = data['promotion'];

          // Récupération de la taille de la liste 'promotions'
          return promotions.length;
        }
      }

      // Retourner 0 si la clé 'promotions' est absente ou vide
      return 0;
    } catch (e) {
      // Gestion des erreurs selon le besoin
      print('Erreur lors de la récupération de la taille des promotions : $e');
      return -1; // Retourner une valeur d'erreur
    }
  }

  void selectHome() {
    setState(() {
      homeButtonSelected = true; // Par défaut, "Home" est inactif
      notifButtonSelected = false;
      profilButtonSelected = false;
    });
    // Vous pouvez ajouter ici le code pour naviguer vers la page d'accueil
  }

  void selectProfil() {
    setState(() {
      profilButtonSelected = true;
      homeButtonSelected = false;
      notifButtonSelected = false;
    });
    // Vous pouvez ajouter ici le code pour naviguer vers la page d'accueil
  }

  void selectNotif() {
    setState(() {
      notifButtonSelected = true;
      homeButtonSelected = false;
      profilButtonSelected = false;
    });
    // Vous pouvez ajouter ici le code pour gérer la page de livraison
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        //widget scroll view wrapping the body
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,

            //Barre de navigation
            pinned: true, //fixation de la navbar
            // title: const Text("Allô Group"), //nom de l'app
            title: Align(
              alignment: Alignment.centerLeft,
              child: const Text("Ahime",
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            actions: [
              // Stack to overlay the IconButton and notification counter
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Notifications();
                          },
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$numberOfPromotions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // imbrication du composant header directement en dessous de la barre de navigation
          Header(),
          ButtonServices(),
          Carousel(),
        ],
      ),

      //============  Bottom Navbar Buttons  ============

      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          selectHome();

          // Navigator.pushNamed(context, '/home');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Home(); // Remplacez DetailPage par votre propre page.
              },
            ),
          );
        },
        // child: Icon(Icons.phone , color: Colors.white,),
        backgroundColor: homeButtonSelected
            ? Colors.orange
            // : Color.fromRGBO(10, 80, 137, 0.8),
            : Colors.white,
        child: Icon(
          Icons.home,
          color: homeButtonSelected
              ? Colors.white
              : Color.fromRGBO(10, 80, 137, 0.8),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(45),
        ),
        child: Container(
          color: Colors.black38,
          child: BottomAppBar(
              shape: CircularNotchedRectangle(),
              child: Row(
                children: [
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      selectProfil();

                      // Navigator.pushNamed(context, '/profilScreen');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ProfileScreen(); // Remplacez DetailPage par votre propre page.
                          },
                        ),
                      );
                    },
                    tooltip: 'Profil',
                    icon: Icon(Icons.person),
                    color: profilButtonSelected ? Colors.orange : Colors.white,
                  ),
                  Spacer(),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      selectNotif();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Notifications(); // Remplacez DetailPage par votre propre page.
                          },
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                    icon: Icon(Icons.notifications),
                    color: notifButtonSelected ? Colors.orange : Colors.white,
                  ),
                  Spacer(),
                ],
              )),
        ),
      ),
    );
  }
}





























































































// import 'package:allogroup/screens/office/notifications/notifications.dart';
// import 'package:allogroup/screens/office/user/profil/profilScreen.dart';
// // import 'package:allogroup/screens/office/widgets/dimensions.dart';
// import 'package:flutter/material.dart';
// import 'screens/office/components/header.dart';
// import 'screens/office/components/accueilservices.dart';
// import 'screens/office/components/carousel_accueil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   bool homeButtonSelected = true; // Par défaut, "Home" est inactif
//   bool notifButtonSelected = false; // Par défaut, "food" est actif
//   bool profilButtonSelected = false; // "Delivery" est inactif
//   int numberOfPromotions = 0;

//   @override
//   void initState() {
//     super.initState();
//     // Appeler la fonction pour récupérer la taille des promotions lors de l'initialisation du widget
//     fetchPromotionsSize();
//   }

//   Future<void> fetchPromotionsSize() async {
//     int size = await getSizeOfPromotions();
//     setState(() {
//       numberOfPromotions = size;
//     });
//   }

//   Future<int> getSizeOfPromotions() async {
//   try {
//     // Accès au document 'zone' dans la collection 'administrateur'
//     DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
//         .collection('administrateur')
//         .doc('admin')
//         .get();

//     if (adminSnapshot.exists) {
//       // Vérification de l'existence de la clé 'promotions'
//       Map<String, dynamic>? data =
//           adminSnapshot.data() as Map<String, dynamic>?;

//       if (data != null && data.containsKey('promotion')) {
//         List<dynamic> promotions = data['promotion'];

//         // Récupération de la taille de la liste 'promotions'
//         return promotions.length;
//       }
//     }

//     // Retourner 0 si la clé 'promotions' est absente ou vide
//     return 0;
//   } catch (e) {
//     // Gestion des erreurs selon le besoin
//     print('Erreur lors de la récupération de la taille des promotions : $e');
//     return -1; // Retourner une valeur d'erreur
//   }
// }
//   void selectHome() {
//     setState(() {
//       homeButtonSelected = true; // Par défaut, "Home" est inactif
//       notifButtonSelected = false;
//       profilButtonSelected = false;
//     });
//     // Vous pouvez ajouter ici le code pour naviguer vers la page d'accueil
//   }

//   void selectProfil() {
//     setState(() {
//       profilButtonSelected = true;
//       homeButtonSelected = false;
//       notifButtonSelected = false;
//     });
//     // Vous pouvez ajouter ici le code pour naviguer vers la page d'accueil
//   }

//   void selectNotif() {
//     setState(() {
//       notifButtonSelected = true;
//       homeButtonSelected = false;
//       profilButtonSelected = false;
//     });
//     // Vous pouvez ajouter ici le code pour gérer la page de livraison
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         //widget scroll view wrapping the body
//         slivers: [
//           SliverAppBar(
//             automaticallyImplyLeading: false,

//             //Barre de navigation
//             pinned: true, //fixation de la navbar
//             // title: const Text("Allô Group"), //nom de l'app
//             title: Align(
//               alignment: Alignment.centerLeft,
//               child: const Text("Allô Group",
//                   style: TextStyle(color: Colors.white, fontSize: 20)),
//             ),
//             actions: [
//               // Ajout du cercle pour le compteur de notifications
//                 Positioned(
//                   right: 10,
//                   top: 10,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: BoxDecoration(
//                       color: Colors.orange,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 16,
//                       minHeight: 16,
//                     ),
//                     child: Text(
//                       '$numberOfPromotions', // Remplacez cette valeur par le nombre de notifications
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//               IconButton(
//                   //button shopping
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) {
//                           return Notifications();
//                         },
//                       ),
//                     );
//                   },
//                   icon: const Icon(
//                     Icons.notifications,
//                     color: Colors.white,
//                   )),    
//             ],
//           ),
//           // imbrication du composant header directement en dessous de la barre de navigation
//           Header(),
//           ButtonServices(),
//           Carousel(),
//         ],
//       ),

//       //============  Bottom Navbar Buttons  ============

//       extendBody: true,
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           selectHome();

//           // Navigator.pushNamed(context, '/home');
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) {
//                 return Home(); // Remplacez DetailPage par votre propre page.
//               },
//             ),
//           );
//         },
//         // child: Icon(Icons.phone , color: Colors.white,),
//         backgroundColor: homeButtonSelected
//             ? Colors.orange
//             // : Color.fromRGBO(10, 80, 137, 0.8),
//             : Colors.white,
//         child: Icon(
//           Icons.home,
//           color: homeButtonSelected
//               ? Colors.white
//               : Color.fromRGBO(10, 80, 137, 0.8),
//         ),
//       ),
//       bottomNavigationBar: ClipRRect(
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(45),
//         ),
//         child: Container(
//           color: Colors.black38,
//           child: BottomAppBar(
//               shape: CircularNotchedRectangle(),
//               child: Row(
//                 children: [
//                   Spacer(),
//                   IconButton(
//                     onPressed: () {
//                       selectProfil();

//                       // Navigator.pushNamed(context, '/profilScreen');
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) {
//                             return ProfileScreen(); // Remplacez DetailPage par votre propre page.
//                           },
//                         ),
//                       );
//                     },
//                     tooltip: 'Profil',
//                     icon: Icon(Icons.person),
//                     color: profilButtonSelected ? Colors.orange : Colors.white,
//                   ),
//                   Spacer(),
//                   Spacer(),
//                   IconButton(
//                     onPressed: () {
//                       selectNotif();
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) {
//                             return Notifications(); // Remplacez DetailPage par votre propre page.
//                           },
//                         ),
//                       );
//                     },
//                     tooltip: 'Notifications',
//                     icon: Icon(Icons.notifications),
//                     color: notifButtonSelected ? Colors.orange : Colors.white,
//                   ),
//                   Spacer(),
//                 ],
//               )),
//         ),
//       ),
//     );
//   }
// }

