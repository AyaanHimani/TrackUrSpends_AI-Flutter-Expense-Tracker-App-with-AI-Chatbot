# TrackUrSpends AI

Track and Manage Expenses 

## Overview

TrackUrSpends is a Flutter application designed to help users track and manage their expenses. It features user authentication, data storage in Firestore, and a conversational AI assistant using Dialogflow.

**Note:** This app is optimized for Android users. Android users can download the app from the repository by clicking the APK in the [Download](Download) folder.

## Features

- **Expense Tracking:** Add, edit, and delete expense entries.
- **Data Visualization:** View expenses through various charts and graphs.
- **User Authentication:** Secure sign-up and login using Firebase Auth.
- **Reminders:** Set and manage reminders for expenses.
- **AI Assistant:** Get insights and tips through the TUrS AI chatbot powered by Dialogflow.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Account](https://firebase.google.com/)
- [Dialogflow Account](https://dialogflow.cloud.google.com/)

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/yourusername/TrackUrSpends.git
   ```
2. Navigate to the project directory
   ```sh
   cd TrackUrSpends
   ```
3. Install dependencies
   ```sh
   flutter pub get
   ```

### Firebase Setup

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android and iOS app to your Firebase project.
3. Download the `google-services.json` file for Android and place it in `android/app/`.
4. Download the `GoogleService-Info.plist` file for iOS and place it in `ios/Runner/`.
5. Follow the instructions to configure Firebase for Flutter [here](https://firebase.flutter.dev/docs/overview).

### Dialogflow Setup

1. Create a Dialogflow agent in the [Dialogflow Console](https://dialogflow.cloud.google.com/).
2. Download the service account key file and save it as `assets/dialog_flow_auth.json`.

### Running the App

```sh
flutter run
```

## Usage

- **Home Page:** Overview of all expenses.
- **Add Expense:** Add new expense entries.
- **View Charts:** Visualize expenses using different types of charts.
- **Reminders:** Set reminders for expenses.
- **TUrS AI:** Interact with the AI assistant for tips and insights.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

LinkedIn: [Ayaan Himani] (https://www.linkedin.com/in/ayaan-himani-1a4923287/)

Ayaan Himani - [ayaanhimani@gmail.com](mailto:ayaanhimani@gmail.com)

Project Link: [https://github.com/yourusername/TrackUrSpends](https://github.com/yourusername/TrackUrSpends)

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Dialogflow](https://dialogflow.cloud.google.com/)


