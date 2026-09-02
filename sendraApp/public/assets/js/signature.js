document.addEventListener('DOMContentLoaded', function () {
    const canvas = document.getElementById('signature-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const defaultImage = document.getElementById('default-image');
    const existingImage = document.getElementById('existing-damage-image');
    let vehicleType = document.querySelector('.damage-vehicle-choice:checked')?.value || 'car';
    // Correction : l'Admin ne voyait jamais les dommages déjà constatés par
    // l'agent — le canvas repartait toujours du gabarit vierge. Si une
    // image existe déjà pour ce signalement, on l'affiche en entier (sans
    // recadrage voiture/moto, ce n'est plus le gabarit à deux panneaux)
    // jusqu'à ce qu'un type de véhicule soit explicitement choisi.
    let showingExistingImage = !!existingImage;

    function drawDefaultImage() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        if (showingExistingImage) {
            ctx.drawImage(existingImage, 0, 0, canvas.width, canvas.height);
            return;
        }

        // L'image gabarit regroupe voiture (partie gauche) et moto (partie
        // droite). On ne dessine que le véhicule choisi.
        if (vehicleType === 'motorcycle') {
            ctx.drawImage(defaultImage, 425, 0, 234, 154, 105, 25, 550, 310);
        } else {
            ctx.drawImage(defaultImage, 0, 0, 430, 154, 25, 35, 710, 290);
        }
    }

    if (showingExistingImage) {
        if (existingImage.complete) drawDefaultImage();
        else existingImage.addEventListener('load', drawDefaultImage, { once: true });
    } else if (defaultImage.complete) {
        drawDefaultImage();
    } else {
        defaultImage.addEventListener('load', drawDefaultImage, { once: true });
    }

    document.querySelectorAll('.damage-vehicle-choice').forEach((choice) => {
        choice.addEventListener('change', (event) => {
            // Choisir un type de véhicule sur une image existante n'a pas
            // de sens (ce n'est plus le gabarit à deux panneaux) — on
            // repart du gabarit vierge pour une nouvelle annotation.
            showingExistingImage = false;
            vehicleType = event.target.value;
            drawDefaultImage();
        });
    });

    let isDrawing = false;
    let lastX = 0;
    let lastY = 0;

    function pointFromEvent(e) {
        const rect = canvas.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        return {
            x: (clientX - rect.left) * canvas.width / rect.width,
            y: (clientY - rect.top) * canvas.height / rect.height,
        };
    }

    function startDrawing(e) {
        e.preventDefault();
        const point = pointFromEvent(e);
        isDrawing = true;
        lastX = point.x;
        lastY = point.y;
    }

    function draw(e) {
        if (!isDrawing) return;
        e.preventDefault();
        const point = pointFromEvent(e);

        ctx.beginPath();
        ctx.moveTo(lastX, lastY);
        ctx.lineTo(point.x, point.y);
        ctx.lineWidth = 3;
        ctx.lineCap = 'round';
        ctx.strokeStyle = '#d32f2f';
        ctx.stroke();

        lastX = point.x;
        lastY = point.y;
    }

    canvas.addEventListener('mousedown', startDrawing);
    canvas.addEventListener('mousemove', draw);
    canvas.addEventListener('touchstart', startDrawing, { passive: false });
    canvas.addEventListener('touchmove', draw, { passive: false });

    canvas.addEventListener('mouseup', () => isDrawing = false);
    canvas.addEventListener('mouseout', () => isDrawing = false);
    canvas.addEventListener('touchend', () => isDrawing = false);
    canvas.addEventListener('touchcancel', () => isDrawing = false);

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
