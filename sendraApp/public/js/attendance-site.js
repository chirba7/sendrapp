document.addEventListener('DOMContentLoaded', () => {
    const latitude = document.getElementById('latitude');
    const longitude = document.getElementById('longitude');
    const radius = document.getElementById('radius_meters');
    if (typeof L === 'undefined') {
        document.getElementById('map-message').textContent = 'Carte indisponible. Vous pouvez saisir les coordonnées ci-dessous.';
        return;
    }
    const map = L.map('attendance-map').setView([14.7167, -17.4677], 14);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19, attribution: '© OpenStreetMap',
    }).addTo(map);
    let marker, circle;
    function draw(recenter = false) {
        const lat = Number.parseFloat(latitude.value), lng = Number.parseFloat(longitude.value);
        const meters = Number.parseFloat(radius.value);
        if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) return;
        if (!marker) {
            marker = L.marker([lat, lng], {draggable: true}).addTo(map);
            marker.on('dragend', () => setPosition(marker.getLatLng()));
        } else marker.setLatLng([lat, lng]);
        if (Number.isFinite(meters) && meters >= 10 && meters <= 5000) {
            if (!circle) circle = L.circle([lat, lng], {radius: meters, color: '#198754'}).addTo(map);
            else circle.setLatLng([lat, lng]).setRadius(meters);
        }
        if (recenter) map.panTo([lat, lng]);
    }
    function setPosition(position) {
        latitude.value = position.lat.toFixed(7);
        longitude.value = position.lng.toFixed(7);
        draw();
    }
    map.on('click', event => setPosition(event.latlng));
    latitude.addEventListener('change', () => draw(true));
    longitude.addEventListener('change', () => draw(true));
    radius.addEventListener('input', () => draw());
    draw(true);
});
