@extends('layouts.master')
@section('session')


<link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css" integrity="sha512-Rksm5RenBEKSKFjgI3a41vrjkw4EVPlJ3+OiI65vTjIdo9brlAacEuKOiQ5OFh7cOI1bkDwLqdLw3Zg0cRJAAQ==" crossorigin="" />
<link rel="stylesheet" type="text/css" href="https://unpkg.com/leaflet.markercluster@1.3.0/dist/MarkerCluster.css" />
<link rel="stylesheet" type="text/css" href="https://unpkg.com/leaflet.markercluster@1.3.0/dist/MarkerCluster.Default.css" />
<style type="text/css">
    #map {
        height: 500px;
    }

    .leaflet-popup-content-wrapper {
        border-radius: 0px;
        width: 250px;
        height: 250px;
        display: flex;
        justify-content: center;
        align-items: center;
    }
</style>
<section class="section ">
    <div class="container-fluid ">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title ">
                        <h2 class="text-success">Cartographie</h2>
                    </div>
                </div>
            </div>
        </div>
        <div id="map">
        </div>
</section>
<!-- Fichiers Javascript -->
<script src="https://unpkg.com/leaflet@1.3.1/dist/leaflet.js" integrity="sha512-/Nsx9X4HebavoBvEBuyp3I7od5tA0UzAxs+j83KgC8PU0kgB4XiK4Lfe4y4cgBtaRJQEIFCW+oC506aPT2L1zw==" crossorigin=""></script>
<script type='text/javascript' src='https://unpkg.com/leaflet.markercluster@1.3.0/dist/leaflet.markercluster.js'></script>
<script>
    let map, markers = [];
    /* ----------------------------- Initialize Map 
    function initMap() {
        map = L.map('map', {
            center: {
                lat: 14.7627, // Latitude de Dakar
                lng: -17.3441, // Longitude de Dakar
            },
            zoom: 10.5 // Zoom initial
        });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap'
        }).addTo(map);

        map.on('click', mapClicked);
        initMarkers();
    }
----------------------------- */

    /* ----------------------------- Initialize Map ----------------------------- */
    function initMap() {
        map = L.map('map', {
            center: {
                lat: 14.7627, // Latitude de Dakar
                lng: -17.3441, // Longitude de Dakar
            },
            zoom: 10.5 // Zoom initial
        });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap'
        }).addTo(map);

        map.on('click', mapClicked);
        initMarkers();

        // Ajouter la gestion de l'événement zoomend
        map.on('zoomend', function() {
            // initMarkers();
            // Recalculer les positions des marqueurs en fonction du zoom
            for (let i = 0; i < markers.length; i++) {
                const marker = markers[i];
                newMarker.addTo(map);
                markers[i] = newMarker; // Mettre à jour la référence du marqueur dans le tableau
            }
        });
    }

    initMap();

    /* --------------------------- Initialize Markers --------------------------- */
    function initMarkers() {
        const initialMarkers = <?php echo json_encode($initialMarkers); ?>;
        console.log(initialMarkers);
        for (let index = 0; index < initialMarkers.length; index++) {
            const data = initialMarkers[index];
            const marker = generateMarker(data, index);
            const baseUrl = "{{ asset('https://backend.sendra.sn/storage') }}";
            const imageUrl = baseUrl + "/" + data.image;
            const popupContent = `
                <div class="square-popup">
                    <b>${data.titre}</b>
                    <br>
                    <img src="${imageUrl}" alt="Marker Image" style="width: 230px; height: 230px">
                </div>
            `;
            marker.addTo(map).bindPopup(popupContent);
            marker.bindPopup(popupContent, {
                className: 'custom-popup'
            });
            markers.push(marker);
        }
    }
    // 
    function generateMarker(data, index) {
        let customIcon = L.icon({
            iconUrl: '{{ asset("img/icons8-location-pin-48.png") }}', // Chemin vers l'icône personnalisée
            iconSize: [30, 30],
            iconAnchor: [15, 15], // Point d'ancrage au centre de l'icône (30/2 = 15)
            popupAnchor: [0, -15], // Ajustement de la fenêtre contextuelle par rapport à l'icône
        });

        // Créer le marqueur avec l'icône personnalisée
        return L.marker([data.latitude, data.longitude], {
            icon: customIcon,
            draggable: false
        });
    }
    /* ------------------------- Handle Map Click Event ------------------------- */
    function mapClicked($event) {
        console.log(map);
        console.log($event.latlng.lat, $event.latlng.lng);
    }

    /* ------------------------ Handle Marker Click Event ----------------------- */
    function markerClicked($event, index) {
        console.log(map);
        console.log($event.latlng.lat, $event.latlng.lng);
    }

    /* ----------------------- Handle Marker DragEnd Event ---------------------- */
    function markerDragEnd($event, index) {
        console.log(map);
        console.log($event.target.getLatLng());
    }
</script>



@endsection