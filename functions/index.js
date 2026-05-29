/* eslint-disable */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// 1. Notificar al Departamento de TI cuando se crea una nueva solicitud
exports.notifyTIOnNewRequest = functions.firestore
    .document('requests/{requestId}')
    .onCreate(async (snap, context) => {
        const requestData = snap.data();
        const docenteName = requestData.userName || 'Un docente';

        // Buscar a todos los usuarios con rol 'ti'
        const tiUsersSnapshot = await admin.firestore()
            .collection('users')
            .where('role', '==', 'ti')
            .get();

        if (tiUsersSnapshot.empty) {
            console.log('No hay usuarios TI registrados.');
            return null;
        }

        const tokens = [];
        tiUsersSnapshot.forEach(doc => {
            const userData = doc.data();
            if (userData.fcmToken) {
                tokens.push(userData.fcmToken);
            }
        });

        if (tokens.length === 0) {
            console.log('Ningún usuario TI tiene token FCM válido.');
            return null;
        }

        const payload = {
            notification: {
                title: 'Nueva Solicitud TI',
                body: `${docenteName} ha enviado una nueva solicitud.`
            }
        };

        return admin.messaging().sendToDevice(tokens, payload);
    });

// 2. Notificar al Docente cuando su solicitud es aceptada/rechazada
exports.notifyDocenteOnRequestUpdate = functions.firestore
    .document('requests/{requestId}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // Si el estado no ha cambiado, no hacer nada
        if (newValue.status === previousValue.status) {
            return null;
        }

        // Si sigue en 'pending', no hacer nada
        if (newValue.status === 'pending') {
            return null;
        }

        const userId = newValue.userId;
        const statusStr = newValue.status === 'accepted' ? 'Aceptada' : 'Rechazada';

        // Buscar el token FCM del docente que hizo la solicitud
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.exists) return null;

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
            console.log('El docente no tiene un token FCM registrado.');
            return null;
        }

        const payload = {
            notification: {
                title: `Solicitud ${statusStr}`,
                body: `Tu solicitud ha sido ${statusStr.toLowerCase()} por el departamento TI.`
            }
        };

        return admin.messaging().sendToDevice(fcmToken, payload);
    });