// document.addEventListener('DOMContentLoaded', function () {
//     // Sélection de l'élément canvas
//     const canvas = document.getElementById('signature-canvas');
//     const ctx = canvas.getContext('2d');
//     // Sélectionner l'image de départ
//     const defaultImage = document.getElementById('default-image');

//     // Dessiner l'image de départ sur le canvas
//     function drawDefaultImage() {
//         ctx.drawImage(defaultImage, 0, 0, canvas.width, canvas.height);
//     }
//     // Dessiner l'image de départ sur le canvas
//     drawDefaultImage();

//     // Variables pour la gestion du dessin
//     let isDrawing = false;
//     let lastX = 0;
//     let lastY = 0;

//     // Gestionnaires d'événements pour le dessin
//     canvas.addEventListener('mousedown', (e) => {
//         isDrawing = true;
//         lastX = e.offsetX;
//         lastY = e.offsetY;
//     });

//     canvas.addEventListener('mousemove', (e) => {
//         if (!isDrawing) return;

//         ctx.beginPath();
//         ctx.moveTo(lastX, lastY);
//         ctx.lineTo(e.offsetX, e.offsetY);
//         ctx.stroke();

//         lastX = e.offsetX;
//         lastY = e.offsetY;
//     });

//     canvas.addEventListener('mouseup', () => isDrawing = false);
//     canvas.addEventListener('mouseout', () => isDrawing = false);

//     // Bouton pour effacer la signature
//     const clearSignature = document.getElementById('clear-signature');
//     clearSignature.addEventListener('click', () => {
//         ctx.clearRect(0, 0, canvas.width, canvas.height);
//         drawDefaultImage();
//     });

//     // Bouton pour enregistrer la signature
//     const saveSignature = document.getElementById('save-signature');
//     saveSignature.addEventListener('click', () => {
//         const imgData = canvas.toDataURL('image/png');

//         // Envoyez une requête AJAX à la route de sauvegarde de la signature
//         fetch('/signature/store', {
//             method: 'POST',
//             headers: {
//                 'Content-Type': 'application/json',
//                 'X-CSRF-TOKEN': '{{ csrf_token() }}'
//             },
//             body: JSON.stringify({ signature: imgData })
//         })
//             .then(response => response.json())
//             .then(data => {
//                 console.log(data.message);
//                 // Effectuez d'autres actions si nécessaire
//             })
//             .catch(error => {
//                 console.error('Erreur :', error);
//             });
//     });
// });

document.addEventListener('DOMContentLoaded', function () {
    const canvas = document.getElementById('signature-canvas');
    const ctx = canvas.getContext('2d');
    const defaultImage = document.getElementById('default-image');

    function drawDefaultImage() {
        ctx.drawImage(defaultImage, 0, 0, canvas.width, canvas.height);
    }

    drawDefaultImage();

    let isDrawing = false;
    let lastX = 0;
    let lastY = 0;

    canvas.addEventListener('mousedown', (e) => {
        isDrawing = true;
        lastX = e.offsetX;
        lastY = e.offsetY;
    });

    canvas.addEventListener('mousemove', (e) => {
        if (!isDrawing) return;

        ctx.beginPath();
        ctx.moveTo(lastX, lastY);
        ctx.lineTo(e.offsetX, e.offsetY);
        ctx.stroke();

        lastX = e.offsetX;
        lastY = e.offsetY;
    });

    canvas.addEventListener('mouseup', () => isDrawing = false);
    canvas.addEventListener('mouseout', () => isDrawing = false);

    const clearSignature = document.getElementById('clear-signature');
    clearSignature.addEventListener('click', () => {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        drawDefaultImage();
    });

    document.getElementById('signature-form').addEventListener('submit', function () {
        const imgData = canvas.toDataURL('image/png');
        document.getElementById('signature').value = imgData;
    });
});