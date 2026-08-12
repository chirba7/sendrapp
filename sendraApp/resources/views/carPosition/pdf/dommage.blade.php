<!DOCTYPE html>
<html>

<head>
    <title>Signature Pad</title>
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

        #signature-controls {
            margin-top: 10px;
        }

        #clear-signature,
        #save-signature {
            padding: 8px 16px;
            font-size: 14px;
            border-radius: 4px;
            cursor: pointer;
        }

        #clear-signature {
            background-color: #f44336;
            color: #fff;
            border: none;
        }

        #save-signature {
            background-color: #4caf50;
            color: #fff;
            border: none;
        }

        #clear-signature:hover,
        #save-signature:hover {
            opacity: 0.8;
        }
    </style>
</head>

<body>
    <div id="signature-pad">
        <img id="default-image" src="{{ asset('img/constation image.png') }}" style="display: none;">
        <canvas id="signature-canvas" width="500" height="300"></canvas>
        <div id="signature-controls">
            <button id="clear-signature">Effacer</button>
            <button id="save-signature">Enregistrer</button>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.3.1/jspdf.umd.min.js"></script>
    <script src="{{ asset('assets/js/signature.js') }}"></script>
</body>

</html>