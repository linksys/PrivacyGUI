importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyCvTujhXf_EeAuXWeecLeDEw4FH9IuNzqc",
  authDomain: "linksys-app-flutter.firebaseapp.com",
  projectId: "linksys-app-flutter",
  storageBucket: "linksys-app-flutter.appspot.com",
  messagingSenderId: "110788105434",
  appId: "1:110788105434:web:21200bdcd63b0be37281e3",
  measurementId: "G-XWTREXPQW6"
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});
