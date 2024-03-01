importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

console.log('[firebase-messaging-sw] InitApp');
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
