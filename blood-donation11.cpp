#include <iostream>
#include <fstream>
#include <string>

using namespace std;

void adminSection();
void donorSection();
void recipientSection();
void blacklistedPersons();
void inputblacklistPerson();
void showblacklistPersons();
void donateBlood();
void personinfotype();
void recipientInformation();
void donorInformation();
void requestBlood();
void searchtype();
void namesearch();
void bloodgroupsearch();
void areasearch();
void donornamesearch();
void recipientnamesearch();
void donorbloodsearch();
void recipientbloodsearch();
void areasearch();
void donorareasearch();
void recipientareasearch();
void voteridsearch();
void donorvoteridsearch();
void recipientvoteridsearch();
void blacklistedvoteridsearch();
void membershipvoteridsearch();
void becomeMember();
void viewMembershipApplications();
void applyForVisit();
void viewVisitApplications();
bool isBlacklisted(const string& voterId);

int main(){
    int choice;
    do {
        cout << "\nBlood Donation Management System\n";
        cout << "1. Admin Section\n";
        cout << "2. Donor Section\n";
        cout << "3. Recipient Section\n";
        cout << "4. Exit\n";
        cout << "Enter your choice: ";
        cin >> choice;
        switch(choice) {
            case 1:
                adminSection();
                break;
            case 2:
                donorSection();
                break;
            case 3:
                recipientSection();
                break;
            case 4:
                cout << "Exiting program. Thank you!\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(choice != 4);
    return 0;
}

void adminSection(){
    int adminChoice;
    do {
        cout << "\nAdmin Section\n";
        cout << "1. Blacklisted Persons\n";
        cout << "2. Persons Information\n";
        cout << "3. Search a person\n";
        cout << "4. Show the Members\n";
        cout << "5. Show the Visit requests\n";
        cout << "6. Back to Main Menu\n";
        cout << "Enter your choice: ";
        cin >> adminChoice;
        switch(adminChoice){
            case 1:
                blacklistedPersons();
                break;
            case 2:
                personinfotype();
                break;
            case 3:
                searchtype();
                break;
            case 4:
                viewMembershipApplications();
                break;
            case 5:
                viewVisitApplications();
                break;
            case 6:
                cout << "Returning to main menu.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(adminChoice != 6);
}

void donorSection(){
    int donorChoice;
    do {
        cout << "\nDonor Section\n";
        cout << "1. Donate Blood\n";
        cout << "2. Become a Member\n";
        cout << "3. Apply for a Visit\n";
        cout << "4. Back to Main Menu\n";
        cout << "Enter your choice: ";
        cin >> donorChoice;
        switch(donorChoice) {
            case 1:
                donateBlood();
                break;
            case 2:
                becomeMember();
                break;
            case 3:
                applyForVisit();
                break;
            case 4:
                cout << "Returning to main menu.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(donorChoice != 4);
}

void recipientSection(){
    int recipientChoice;
    do {
        cout << "\nRecipient Section\n";
        cout << "1. Request Blood Group\n";
        cout << "2. Back to Main Menu\n";
        cout << "Enter your choice: ";
        cin >> recipientChoice;
        switch(recipientChoice) {
            case 1:
                requestBlood();
                break;
            case 2:
                cout << "Returning to main menu.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(recipientChoice != 2);
}

void blacklistedPersons(){
    int adminChoice;
    do {
        cout << "\nManage Blacklisted Persons\n";
        cout << "1. Input a Person\n";
        cout << "2. Show Persons\n";
        cout << "3. Back to Admin Section\n";
        cout << "Enter your choice: ";
        cin >> adminChoice;
        switch(adminChoice){
            case 1:
                inputblacklistPerson();
                break;
            case 2:
                showblacklistPersons();
                break;
            case 3:
                cout << "Returning to admin section.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(adminChoice != 3);
}

void personinfotype(){
    int personinfoChoice;
    do {
        cout << "\nSelect the folder to open information.\n";
        cout << "1. Donor file\n";
        cout << "2. Recipient file\n";
        cout << "3. Back to Admin Section\n";
        cout << "Enter your choice: ";
        cin >> personinfoChoice;
        switch(personinfoChoice){
            case 1:
                donorInformation();
                break;
            case 2:
                recipientInformation();
                break;
            case 3:
                cout << "Returning to admin section.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(personinfoChoice != 3);
}

void viewMembershipApplications() {
    string line;
    ifstream inFile("membershipApplications.txt");
    if (inFile.is_open()) {
        cout << "\nMembership Applications:\n";
        while (getline(inFile, line)) {
            cout << line << endl;
        }
        inFile.close();
    } else {
        cout << "Unable to open membership applications file.\n";
    }
}

void viewVisitApplications() {
    string line;
    ifstream inFile("visitApplications.txt");
    if (inFile.is_open()) {
        cout << "\nVisit Applications:\n";
        while (getline(inFile, line)) {
            cout << line << endl;
        }
        inFile.close();
    } else {
        cout << "Unable to open visit applications file.\n";
    }
}


void inputblacklistPerson(){
    string voterId, name, bloodGroup, address;
    int age;
    cout << "\nEnter Person's Information:\n";
    cout << "Enter National Voter ID Number of 10 Digits: ";
    cin.ignore();
    getline(cin, voterId);
    cout << "Name: ";
    getline(cin, name);
    cout << "Age: ";
    cin >> age;
    cout << "Blood Group: ";
    cin >> bloodGroup;
    cout << "Address: ";
    cin.ignore();
    getline(cin, address);
    ofstream outFile("blacklistedPersons.txt", ios::app);
    if(outFile.is_open()) {
        outFile << "National Voter ID Number: " << voterId << "\n";
        outFile << "Name: " << name << "\n";
        outFile << "Age: " << age << "\n";
        outFile << "Blood Group: " << bloodGroup << "\n";
        outFile << "Address: " << address << "\n\n";
        cout << "Person's information saved successfully.\n";
        outFile.close();
    } else {
        cout << "Error: Unable to open file.\n";
    }
}

void showblacklistPersons(){
    string line;
    ifstream inFile("blacklistedPersons.txt");
    if(inFile.is_open()) {
        cout << "\nList of Blacklisted Persons:\n";
        while(getline(inFile, line)) {
            cout << line << endl;
        }
        inFile.close();
    } else {
        cout << "No blacklisted persons found.\n";
    }
}

bool isBlacklisted(const string& voterId) {
    string line;
    ifstream inFile("blacklistedPersons.txt");
    if (inFile.is_open()) {
        while (getline(inFile, line)) {
            if (line.find("National Voter ID Number: " + voterId) != string::npos) {
                inFile.close();
                return true;
            }
        }
        inFile.close();
    }
    return false;
}

void donateBlood() {
    string voterId, name, bloodGroup, address, dateOfDonation;
    int age;

    cout << "\nEnter Donor's Information:\n";
    cout << "Enter National Voter ID Number of 10 Digits: ";
    cin.ignore();
    getline(cin, voterId);


    if (isBlacklisted(voterId)) {
        cout << "You are blacklisted. You cannot donate blood.\n";
        return;
    }

    cout << "Name: ";
    getline(cin, name);

    cout << "Age: ";
    cin >> age;

    cout << "Blood Group: ";
    cin >> bloodGroup;

    cout << "Address: ";
    cin.ignore();
    getline(cin, address);


    cout << "Date of Donation (YYYY-MM-DD): ";
    cin >> dateOfDonation;


    ofstream outFile("donorInformation.txt", ios::app);
    if (outFile.is_open()) {
        outFile << "National Voter ID Number: " << voterId << "\n";
        outFile << "Name: " << name << "\n";
        outFile << "Age: " << age << "\n";
        outFile << "Blood Group: " << bloodGroup << "\n";
        outFile << "Address: " << address << "\n";
        outFile << "Date of Donation: " << dateOfDonation << "\n\n";
        cout << "Donor's information saved successfully.\n";
        outFile.close();
    } else {
        cout << "Error: Unable to open file.\n";
    }

    ofstream outFile1("donorname.txt", ios::app);
    if (outFile1.is_open()) {
        outFile1 << "Name: " << name << "\n";
        outFile1 << "National Voter ID Number: " << voterId << "\n";
        outFile1 << "Age: " << age << "\n";
        outFile1 << "Blood Group: " << bloodGroup << "\n";
        outFile1 << "Address: " << address << "\n";
        outFile1 << "Date of Donation: " << dateOfDonation << "\n\n";
        outFile1.close();
    }

    ofstream outFile2("donorblood.txt", ios::app);
    if (outFile2.is_open()) {
        outFile2 << "Blood Group: " << bloodGroup << "\n";
        outFile2 << "National Voter ID Number: " << voterId << "\n";
        outFile2 << "Name: " << name << "\n";
        outFile2 << "Age: " << age << "\n";
        outFile2 << "Address: " << address << "\n";
        outFile2 << "Date of Donation: " << dateOfDonation << "\n\n";
        outFile2.close();
    }

    ofstream outFile3("donorarea.txt", ios::app);
    if (outFile3.is_open()) {
        outFile3 << "Address: " << address << "\n";
        outFile3 << "National Voter ID Number: " << voterId << "\n";
        outFile3 << "Name: " << name << "\n";
        outFile3 << "Age: " << age << "\n";
        outFile3 << "Blood Group: " << bloodGroup << "\n";
        outFile3 << "Date of Donation: " << dateOfDonation << "\n\n";
        outFile3.close();
    }
}

void becomeMember() {
    string voterId, name, fatherName, motherName, bloodGroup, temporaryAddress, permanentAddress, maritalStatus, number, email, sex;
    int age;

    cout << "\nEnter Personal Information:\n";
    cout << "Enter National Voter ID Number of 10 Digits: ";
    cin.ignore();
    getline(cin, voterId);
    cout << "Name: ";
    getline(cin, name);
    cout << "Father's Name: ";
    getline(cin, fatherName);
    cout << "Mother's Name: ";
    getline(cin, motherName);
    cout << "Blood Group: ";
    cin >> bloodGroup;
    cout << "Age: ";
    cin >> age;
    cout << "Sex: ";
    cin >> sex;
    cout << "Temporary Address: ";
    cin.ignore();
    getline(cin, temporaryAddress);
    cout << "Permanent Address: ";
    getline(cin, permanentAddress);
    cout << "Marital Status: ";
    cin >> maritalStatus;
    cout << "Contact Number: ";
    cin >> number;
    cout << "Email: ";
    cin >> email;

    ofstream outFile("membershipApplications.txt", ios::app);
    if (outFile.is_open()) {
        outFile << "National Voter ID Number: " << voterId << endl
                << "Name: " << name << endl
                << "Father's Name: " << fatherName << endl
                << "Mother's Name: " << motherName << endl
                << "Blood Group: " << bloodGroup << endl
                << "Age: " << age << endl
                << "Sex: " << sex << endl
                << "Temporary Address: " << temporaryAddress << endl
                << "Permanent Address: " << permanentAddress << endl
                << "Marital Status: " << maritalStatus << endl
                << "Contact Number: " << number << endl
                << "Email: " << email << endl
                << endl;
        cout << "Membership application saved successfully.\n";
        outFile.close();
    } else {
        cout << "Error: Unable to open file.\n";
    }
}

void applyForVisit() {
    string name, bloodGroup, address, sex;
    int age;
    cout << "\nEnter Patient's Information:\n";
    cout << "Name: ";
    cin.ignore();
    getline(cin, name);
    cout << "Blood Group: ";
    cin >> bloodGroup;
    cout << "Address: ";
    cin.ignore();
    getline(cin, address);
    cout << "Sex: ";
    cin >> sex;
    cout << "Age: ";
    cin >> age;

    ofstream outFile("visitApplications.txt", ios::app);
    if (outFile.is_open()) {
        outFile << "Name: " << name << "\n";
        outFile << "Blood Group: " << bloodGroup << "\n";
        outFile << "Address: " << address << "\n";
        outFile << "Sex: " << sex << "\n";
        outFile << "Age: " << age << "\n\n";
        cout << "Application for visit with a doctor saved successfully.\n";
        outFile.close();
    } else {
        cout << "Error: Unable to open file.\n";
    }
}

void requestBlood(){
    string voterId, name, bloodGroup, address, dateOfTakingBlood;
    int age;
    cout << "\nEnter Recipient's Information:\n";
    cout << "Enter National Voter ID Number of 10 Digits: ";
    cin.ignore();
    getline(cin, voterId);
    cout << "Name: ";
    getline(cin, name);
    cout << "Age: ";
    cin >> age;
    cout << "Blood Group Needed: ";
    cin >> bloodGroup;
    cout << "Address: ";
    cin.ignore();
    getline(cin, address);
    cout << "Date of Taking Blood (YYYY-MM-DD): ";
    cin >> dateOfTakingBlood;
    ofstream outFile("recipientInformation.txt", ios::app);
    if(outFile.is_open()) {
        outFile << "National Voter ID Number: " << voterId << "\n";
        outFile << "Name: " << name << "\n";
        outFile << "Age: " << age << "\n";
        outFile << "Blood Group Needed: " << bloodGroup << "\n";
        outFile << "Address: " << address << "\n";
        outFile << "Date of Taking Blood: " << dateOfTakingBlood << "\n\n";
        cout << "Recipient's information saved successfully.\n";
        outFile.close();
    } else {
        cout << "Error: Unable to open file.\n";
    }

    ofstream outFile1("recipientname.txt", ios::app);
    if (outFile1.is_open()) {
        outFile1 << "Name: " << name << "\n";
        outFile1 << "National Voter ID Number: " << voterId << "\n";
        outFile1 << "Age: " << age << "\n";
        outFile1 << "Blood Group Needed: " << bloodGroup << "\n";
        outFile1 << "Address: " << address << "\n";
        outFile1 << "Date of Taking Blood: " << dateOfTakingBlood << "\n\n";
        outFile1.close();
    }

    ofstream outFile2("recipientblood.txt", ios::app);
    if (outFile2.is_open()) {
        outFile2 << "Blood Group Needed: " << bloodGroup << "\n";
        outFile2 << "National Voter ID Number: " << voterId << "\n";
        outFile2 << "Name: " << name << "\n";
        outFile2 << "Age: " << age << "\n";
        outFile2 << "Address: " << address << "\n";
        outFile2 << "Date of Taking Blood: " << dateOfTakingBlood << "\n\n";
        outFile2.close();
    }

    ofstream outFile3("recipientarea.txt", ios::app);
    if (outFile3.is_open()) {
        outFile3 << "Address: " << address << "\n";
        outFile3 << "National Voter ID Number: " << voterId << "\n";
        outFile3 << "Name: " << name << "\n";
        outFile3 << "Age: " << age << "\n";
        outFile3 << "Blood Group Needed: " << bloodGroup << "\n";
        outFile3 << "Date of Taking Blood: " << dateOfTakingBlood << "\n\n";
        outFile3.close();
    }
}

void recipientInformation(){
    string line;
    ifstream inFile("recipientInformation.txt");
    if(inFile.is_open()) {
        cout << "\nRecipient Information:\n";
        while(getline(inFile, line)) {
            cout << line << endl;
        }
        inFile.close();
    } else {
        cout << "No recipient information found.\n";
    }
}

void donorInformation(){
    string line;
    ifstream inFile("donorInformation.txt");
    if(inFile.is_open()) {
        cout << "\nDonor Information:\n";
        while(getline(inFile, line)) {
            cout << line << endl;
        }
        inFile.close();
    } else {
        cout << "No donor information found.\n";
    }
}

void searchtype(){
    int searchChoice;
    do {
        cout << "\nSelect the type of search\n";
        cout << "1. Voter ID Search\n";
        cout << "2. Name Search\n";
        cout << "3. Blood Group Search\n";
        cout << "4. Area Search\n";
        cout << "5. Back to Admin Section\n";
        cout << "Enter your choice: ";
        cin >> searchChoice;
        switch(searchChoice){
            case 1:
                voteridsearch();
                break;
            case 2:
                namesearch();
                break;
            case 3:
                bloodgroupsearch();
                break;
            case 4:
                areasearch();
                break;
            case 5:
                cout << "Returning to admin section.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(searchChoice != 5);
}

void voteridsearch(){
    int voteridsearchChoice;
    do {
        cout << "\nChoose the file to search\n";
        cout << "1. Donor file\n";
        cout << "2. Recipient file\n";
        cout << "3. Blacklisted file\n";
        cout << "4. Membership file\n";
        cout << "5. Back\n";
        cout << "Enter your choice: ";
        cin >> voteridsearchChoice;
        switch(voteridsearchChoice){
            case 1:
                donorvoteridsearch();
                break;
            case 2:
                recipientvoteridsearch();
                break;
            case 3:
                blacklistedvoteridsearch();
                break;
            case 4:
                membershipvoteridsearch();
                break;
            case 5:
                cout << "Returning.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(voteridsearchChoice != 5);
}

void donorvoteridsearch() {
    string voterId;
    cout << "\nEnter the Voter ID Number to search in donor information: ";
    cin.ignore();
    getline(cin, voterId);

    ifstream inFile("donorInformation.txt");
    if (!inFile) {
        cout << "Unable to open donor file.\n";
        return;
    }

    bool found = false;
    string line;
    cout << "\nSearch Results for Voter ID: " << voterId << endl;
    while (getline(inFile, line)) {
        if (line.find("National Voter ID Number: " + voterId) != string::npos) {
            found = true;

            cout << line << endl;

            for (int i = 0; i < 5; ++i) {
                if (!getline(inFile, line))
                    break;
                cout << line << endl;
            }
            cout << endl;

        }
    }

    inFile.close();

    if (!found) {
        cout << "Voter ID Number not found in Donor File.\n";
    }
}

void recipientvoteridsearch(){
    string voterId;
    cout << "\nEnter the Voter ID Number to search in Recipient File: ";
    cin.ignore();
    getline(cin, voterId);

    ifstream inFile("recipientInformation.txt");
    if (!inFile) {
        cout << "Unable to open recipient file.\n";
        return;
    }

    bool found = false;
    string line;
    cout << "\nSearch Results for Voter ID: " << voterId << endl;
    while (getline(inFile, line)) {
        if (line.find("National Voter ID Number: " + voterId) != string::npos) {
            found = true;
            cout << line << endl;

            for (int i = 0; i < 5; ++i) {
                if (!getline(inFile, line))
                    break;
                cout << line << endl;
            }
            cout << endl;
        }
    }

    inFile.close();

    if (!found) {
        cout << "Voter ID Number not found in Recipient File.\n";
    }

}

void blacklistedvoteridsearch(){
    string voterId;
    cout << "\nEnter the Voter ID Number to search in blacklisted persons: ";
    cin.ignore();
    getline(cin, voterId);

    ifstream inFile("blacklistedPersons.txt");
    if (!inFile) {
        cout << "Error: Unable to open blacklisted persons file.\n";
        return;
    }

    bool found = false;
    string line;
    cout << "\nSearch Results for Voter ID in Blacklisted Persons: " << voterId << endl;
    while (getline(inFile, line)) {
        if (line.find("National Voter ID Number: " + voterId) != string::npos) {
            found = true;
            cout << line << endl;
            for (int i = 0; i < 4; ++i) {
                if (!getline(inFile, line))
                    break;
                cout << line << endl;
            }
            cout << endl;
            break;
        }
    }

    inFile.close();

    if (!found) {
        cout << "Voter ID Number not found in Blacklisted Persons.\n";
    }
}

void membershipvoteridsearch(){
    string voterId;
    cout << "\nEnter the Voter ID Number to search in membership applications: ";
    cin.ignore();
    getline(cin, voterId);

    ifstream inFile("membershipApplications.txt");
    if (!inFile) {
        cout << "Error: Unable to open membership applications file.\n";
        return;
    }

    bool found = false;
    string line;
    cout << "\nSearch Results for Voter ID in Membership Applications: " << voterId << endl;
    while (getline(inFile, line)) {
        if (line.find("National Voter ID Number: " + voterId) != string::npos) {
            found = true;
            cout << line << endl;
            for (int i = 0; i < 11; ++i) {
                if (!getline(inFile, line))
                    break;
                cout << line << endl;
            }
            cout << endl;
            break;
        }
    }

    inFile.close();

    if (!found) {
        cout << "Voter ID Number not found in Membership Applications.\n";
    }
}

void namesearch(){
    int namesearchChoice;
    do {
        cout << "\nChoose the file to search\n";
        cout << "1. Donor file\n";
        cout << "2. Recipient file\n";
        cout << "3. Back\n";
        cout << "Enter your choice: ";
        cin >> namesearchChoice;
        switch(namesearchChoice){
            case 1:
                donornamesearch();
                break;
            case 2:
                recipientnamesearch();
                break;
            case 3:
                cout << "Returning.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(namesearchChoice != 3);
}

void donornamesearch(){
    string searchName;
    cout << "\nEnter the name of the donor to search: ";
    cin.ignore();
    getline(cin, searchName);

    string line;
    ifstream inFile("donorname.txt");
    if (inFile.is_open()) {
        bool found = false;
        cout << "\nSearch Results for Donor: " << searchName << endl;
        while (getline(inFile, line)) {
            if (line.find("Name: " + searchName) != string::npos) {
                found = true;
                for (int i = 0; i < 5; ++i) {
                    cout << line << endl;
                    getline(inFile, line);
                }
                cout << endl;
            }
        }
        if (!found) {
            cout << "Donor with name '" << searchName << "' not found.\n";
        }
        inFile.close();
    } else {
        cout << "Unable to open donor file.\n";
    }
}

void recipientnamesearch(){
    string searchName;
    cout << "\nEnter the name of the recipient to search: ";
    cin.ignore();
    getline(cin, searchName);
    string line;
    ifstream inFile("recipientname.txt");
    if (inFile.is_open()) {
        bool found = false;
        cout << "\nSearch Results for Recipient: " << searchName << endl;
        while (getline(inFile, line)) {
            if (line.find("Name: " + searchName) != string::npos) {
                found = true;
                for (int i = 0; i < 5; ++i) {
                    cout << line << endl;
                    getline(inFile, line);
                }
                cout << endl;
            }
        }
        if (!found) {
            cout << "Recipient with name '" << searchName << "' not found.\n";
        }
        inFile.close();
    } else {
        cout << "Unable to open donor file.\n";
    }
}

void bloodgroupsearch(){
    int bloodsearchChoice;
    do {
        cout << "\nChoose the file to search\n";
        cout << "1. Donor file\n";
        cout << "2. Recipient file\n";
        cout << "3. Back\n";
        cout << "Enter your choice: ";
        cin >> bloodsearchChoice;
        switch(bloodsearchChoice){
            case 1:
                donorbloodsearch();
                break;
            case 2:
                recipientbloodsearch();
                break;
            case 3:
                cout << "Returning.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(bloodsearchChoice != 3);
}

void donorbloodsearch(){
    string searchBloodGroup;
    cout << "\nEnter the blood group to search: ";
    cin >> searchBloodGroup;
    string line;
    ifstream inFile("donorblood.txt");
    if (inFile.is_open()) {
        bool found = false;
        cout << "\nSearch Results for Blood Group: " << searchBloodGroup << endl;
        while (getline(inFile, line)) {
            if (line.find("Blood Group: " + searchBloodGroup) != string::npos) {
                found = true;
                for (int i = 0; i < 5; ++i) {
                    cout << line << endl;
                    getline(inFile, line);
                }
                cout << endl;
            }
        }
        if (!found) {
            cout << "No donors found with this blood group '" << searchBloodGroup << "'.\n";
        }
        inFile.close();
    } else {
        cout << "Unable to open donor file.\n";
    }
}

void recipientbloodsearch(){
    string searchBloodGroup;
    cout << "\nEnter the blood group to search: ";
    cin >> searchBloodGroup;
    string line;
    ifstream inFile("recipientblood.txt");
    if (inFile.is_open()) {
        bool found = false;
        cout << "\nSearch Results for Blood Group: " << searchBloodGroup << endl;
        while (getline(inFile, line)) {
            if (line.find("Blood Group Needed: " + searchBloodGroup) != string::npos) {
                found = true;
                for (int i = 0; i < 5; ++i) {
                    cout << line << endl;
                    getline(inFile, line);
                }
                cout << endl;
            }
        }
        if (!found) {
            cout << "No recipient found with this blood group '" << searchBloodGroup << "'.\n";
        }
        inFile.close();
    } else {
        cout << "Unable to open donor file.\n";
    }
}

void areasearch(){
    int areasearchChoice;
    do {
        cout << "\nChoose the file to search\n";
        cout << "1. Donor file\n";
        cout << "2. Recipient file\n";
        cout << "3. Back\n";
        cout << "Enter your choice: ";
        cin >> areasearchChoice;
        switch(areasearchChoice){
            case 1:
                donorareasearch();
                break;
            case 2:
                recipientareasearch();
                break;
            case 3:
                cout << "Returning.\n";
                break;
            default:
                cout << "Invalid choice. Please try again.\n";
        }
    } while(areasearchChoice != 3);
}

void donorareasearch(){
    string searchArea;
    cout << "\nEnter the area to search: ";
    cin.ignore();
    getline(cin, searchArea);
    string line;
    ifstream inFile("donorarea.txt");
    if (inFile.is_open()) {
        bool found = false;
        cout << "\nSearch Results for Area: " << searchArea << endl;
        while (getline(inFile, line)) {
            if (line.find("Address: " + searchArea) != string::npos) {
                found = true;
                for (int i = 0; i < 5; ++i) {
                    cout << line << endl;
                    getline(inFile, line);
                }
                cout << endl;
            }
        }
        if (!found) {
            cout << "No donors found in area '" << searchArea << "'.\n";
        }
        inFile.close();
    } else {
        cout << "Unable to open donor file.\n";
    }
}

void recipientareasearch(){
    string searchArea;
    cout << "\nEnter the area to search: ";
    cin.ignore();
    getline(cin, searchArea);
    string line;
    ifstream inFile("recipientarea.txt");
    if (inFile.is_open()) {
        bool found = false;
        cout << "\nSearch Results for Area: " << searchArea << endl;
        while (getline(inFile, line)) {
            if (line.find("Address: " + searchArea) != string::npos) {
                found = true;
                for (int i = 0; i < 5; ++i) {
                    cout << line << endl;
                    getline(inFile, line);
                }
                cout << endl;
            }
        }
        if (!found) {
            cout << "No recipient found in area '" << searchArea << "'.\n";
        }
        inFile.close();
    } else {
        cout << "Unable to open donor file.\n";
    }
}

