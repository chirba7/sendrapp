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