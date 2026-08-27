<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Demande d'approbation Sendra</title>
</head>
<body style="margin:0;padding:0;background:#f2f6f3;font-family:Arial,Helvetica,sans-serif;color:#1f2933;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f2f6f3;padding:28px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;box-shadow:0 8px 24px rgba(17,94,45,.10);">
                <tr>
                    <td align="center" style="padding:28px 32px 22px;border-top:7px solid #0b8738;">
                        <img src="<?php echo e($message->embed(public_path('images/email/sendra-logo.png'))); ?>"
                             width="245" alt="Sendra"
                             style="display:block;width:245px;max-width:80%;height:auto;border:0;">
                    </td>
                </tr>
                <tr>
                    <td style="padding:0 38px 34px;">
                        <div style="display:inline-block;background:#e8f6ed;color:#087333;border-radius:999px;padding:7px 13px;font-size:12px;font-weight:bold;text-transform:uppercase;letter-spacing:.5px;">
                            Approbation requise
                        </div>
                        <h1 style="margin:18px 0 10px;font-size:25px;line-height:1.25;color:#111827;">
                            Une constatation attend votre validation
                        </h1>
                        <p style="margin:0 0 24px;color:#59636e;font-size:16px;line-height:1.6;">
                            L'agent a terminé la saisie des dommages. Consultez le dossier avant de l'approuver ou de le rejeter.
                        </p>

                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f7faf8;border:1px solid #dce9e0;border-radius:12px;">
                            <tr>
                                <td style="padding:18px 20px;border-bottom:1px solid #dce9e0;color:#667085;font-size:14px;">Signalement</td>
                                <td align="right" style="padding:18px 20px;border-bottom:1px solid #dce9e0;font-weight:bold;color:#111827;">N° <?php echo e($signalement->id); ?></td>
                            </tr>
                            <tr>
                                <td style="padding:18px 20px;border-bottom:1px solid #dce9e0;color:#667085;font-size:14px;">Titre</td>
                                <td align="right" style="padding:18px 20px;border-bottom:1px solid #dce9e0;font-weight:bold;color:#111827;"><?php echo e($signalement->title ?: 'Sans titre'); ?></td>
                            </tr>
                            <tr>
                                <td style="padding:18px 20px;color:#667085;font-size:14px;">Commune</td>
                                <td align="right" style="padding:18px 20px;font-weight:bold;color:#111827;"><?php echo e($signalement->commune ?: 'Non renseignée'); ?></td>
                            </tr>
                        </table>

                        <table role="presentation" cellspacing="0" cellpadding="0" style="margin:28px auto 8px;">
                            <tr>
                                <td align="center" bgcolor="#0b8738" style="border-radius:10px;">
                                    <a href="<?php echo e($detailsUrl); ?>" style="display:inline-block;padding:15px 26px;color:#ffffff;text-decoration:none;font-size:16px;font-weight:bold;">
                                        Ouvrir dans le back-office
                                    </a>
                                </td>
                            </tr>
                        </table>
                        <p style="margin:16px 0 0;text-align:center;color:#8a949e;font-size:12px;line-height:1.5;">
                            Si le bouton ne fonctionne pas, copiez ce lien :<br>
                            <a href="<?php echo e($detailsUrl); ?>" style="color:#0b8738;word-break:break-all;"><?php echo e($detailsUrl); ?></a>
                        </p>
                    </td>
                </tr>
                <tr>
                    <td align="center" style="background:#073d20;padding:20px 30px;color:#d6eadc;font-size:12px;line-height:1.5;">
                        Sendra — Sénégalaise de Déconstruction et de Recyclage Automobile<br>
                        Message automatique, merci de ne pas y répondre.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
<?php /**PATH /var/www/html/resources/views/emails/approval-request.blade.php ENDPATH**/ ?>