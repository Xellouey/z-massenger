import 'dart:developer';
import 'package:chatzy/config.dart';
import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class NewContactController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  GlobalKey<FormState> profileGlobalKey = GlobalKey<FormState>();
  String? dialCode;
  bool isExist = false, isExistInApp = false;

  @override
  void onReady() {
    final String systemLocales =
    WidgetsBinding.instance.platformDispatcher.locale.countryCode!;
    List country = countriesEnglish;
    int index =
    country.indexWhere((element) => element['code'] == systemLocales);
    dialCode = country[index]['dial_code'];
    update();
    log("DIAL : $dialCode");
    update();

    //  implement onReady
    super.onReady();
  }

  Future<void> onContactSave() async {
    FocusScope.of(Get.context!).requestFocus(FocusNode());

    // Check if the user has granted permission to access contacts
    if (!await FlutterContacts.requestPermission()) {
      log("Permission to access contacts denied.");
      return;
    }

    final name = nameController.text;
    final email = emailController.text;
    final phone = "$dialCode${phoneController.text}";

    // Create a new contact
    Contact contact = Contact(
      name: Name(first: name),
      phones: [
        Phone(
          phone, /* label: 'mobile'*/
        )
      ],
      emails: [
        Email(
          email, /*label: 'personal'*/
        )
      ],
    );

    log("contact: $contact");

    try {
      // Fetch contacts to check if the phone number already exists
      List<Contact> existingContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      bool isExist = existingContacts.any(
              (c) => c.phones.any((p) => p.number.replaceAll(' ', '') == phone));

      if (isExist) {
        log("Contact already exists in the phonebook.");
      } else {
        // Check if the phone number exists in your app database
        final userDocs = await FirebaseFirestore.instance
            .collection(collectionName.users)
            .where("phone", isEqualTo: phone)
            .get();

        if (userDocs.docs.isNotEmpty) {
          log("Phone number exists in the app database.");
          isExistInApp = false;
        } else {
          log("Phone number does not exist in the app database.");
          isExistInApp = true;
        }

        // Add contact to the phonebook
        await FlutterContacts.insertContact(contact);
        log("Contact added successfully.");
      }
    } catch (e) {
      log("Error while saving contact: $e");
    }

    update(); // Update the UI or state
    Get.back(); // Close the current screen
  }
}
