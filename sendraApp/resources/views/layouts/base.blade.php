<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link href="{{asset('img/sendra.ico')}}" rel="icon">
    <title>SENDRA APP</title>

    <!-- ========== All CSS files linkup ========= -->
    <link rel="stylesheet" href="{{asset('assets/css/lineicons.css')}}" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" href="{{asset('assets/css/materialdesignicons.min.css')}}" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" href="{{asset('assets/css/bootstrap.min.css')}}" />
    <link rel="stylesheet" href="{{asset('assets/css/fullcalendar.css')}}" />
    <link rel="stylesheet" href="{{asset('assets/css/fullcalendar.css')}}" />
    <link rel="stylesheet" href="{{asset('assets/css/main.css')}}" />
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <style>
        #signature-pad {
            text-align: center;
            margin-bottom: 20px;
        }

        #signature-canvas {
            border: 1px solid #000;
            background-color: #fff;
            cursor: crosshair;
        }
    </style>
</head>

<body>
    <!-- ======== Preloader =========== -->
    <div id="preloader">
        <div class="spinner"></div>
    </div>
    <!-- ======== Preloader =========== -->
    @yield('contenu')


    <!-- ========= All Javascript files linkup ======== -->
    <script src="{{asset('assets/js/bootstrap.bundle.min.js')}}"></script>
    <script src="{{asset('assets/js/Chart.min.js')}}"></script>
    <script src="{{asset('assets/js/dynamic-pie-chart.js')}}"></script>
    <script src="{{asset('assets/js/moment.min.js')}}"></script>
    <script src="{{asset('assets/js/fullcalendar.js')}}"></script>
    <script src="{{asset('assets/js/jvectormap.min.js')}}"></script>
    <script src="{{asset('assets/js/world-merc.js')}}"></script>
    <script src="{{asset('assets/js/polyfill.js')}}"></script>
    <script src="{{asset('assets/js/main.js')}}"></script>

</body>

</html>