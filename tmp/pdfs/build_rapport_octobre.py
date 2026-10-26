from pathlib import Path
import re
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable


ROOT = Path(r"C:\Projets\sendrapp\sendra")
SOURCE = ROOT / "RAPPORT_SEMAINE 19 au 23 octobre 2026.md"
OUTPUT = ROOT / "output" / "pdf" / "Rapport Sendra semaine du 19 au 23 octobre 2026.pdf"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

pdfmetrics.registerFont(TTFont("Arial", r"C:\Windows\Fonts\arial.ttf"))
pdfmetrics.registerFont(TTFont("Arial-Bold", r"C:\Windows\Fonts\arialbd.ttf"))
pdfmetrics.registerFontFamily("Arial", normal="Arial", bold="Arial-Bold")

ink = colors.HexColor("#18221D")
green = colors.HexColor("#08783D")
muted = colors.HexColor("#5E6861")

styles = {
    "title": ParagraphStyle("title", fontName="Arial-Bold", fontSize=20, leading=25,
                             textColor=ink, spaceAfter=12),
    "meta": ParagraphStyle("meta", fontName="Arial", fontSize=9.5, leading=14,
                            textColor=muted, spaceAfter=3),
    "h2": ParagraphStyle("h2", fontName="Arial-Bold", fontSize=12.5, leading=17,
                          textColor=ink, spaceBefore=17, spaceAfter=7, keepWithNext=True),
    "h3": ParagraphStyle("h3", fontName="Arial-Bold", fontSize=10.8, leading=15,
                          textColor=ink, spaceBefore=11, spaceAfter=5, keepWithNext=True),
    "body": ParagraphStyle("body", fontName="Arial", fontSize=9.7, leading=14.4,
                            textColor=ink, spaceAfter=7, alignment=TA_LEFT),
    "bullet": ParagraphStyle("bullet", fontName="Arial", fontSize=9.5, leading=14.1,
                              textColor=ink, leftIndent=13, firstLineIndent=-9, spaceAfter=4),
}


def inline(text):
    text = escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    return text


def footer(canvas, doc):
    canvas.saveState()
    w, _ = A4
    canvas.setStrokeColor(colors.HexColor("#DCE4DF"))
    canvas.line(20 * mm, 17 * mm, w - 20 * mm, 17 * mm)
    canvas.setFont("Arial", 8)
    canvas.setFillColor(muted)
    canvas.drawString(20 * mm, 12 * mm, "Sendra  |  Rapport hebdomadaire  |  19-23 octobre 2026")
    canvas.drawRightString(w - 20 * mm, 12 * mm, str(doc.page))
    canvas.restoreState()


story = []
for raw in SOURCE.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line:
        continue
    if line == "---":
        story.append(Spacer(1, 5 * mm))
        story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#DCE4DF")))
    elif line.startswith("# "):
        story.append(Paragraph(inline(line[2:]), styles["title"]))
    elif line.startswith("## "):
        story.append(Paragraph(inline(line[3:]), styles["h2"]))
    elif line.startswith("### "):
        story.append(Paragraph(inline(line[4:]), styles["h3"]))
    elif line.startswith("- "):
        story.append(Paragraph("• " + inline(line[2:]), styles["bullet"]))
    elif re.match(r"^\d+\. ", line):
        story.append(Paragraph(inline(line), styles["bullet"]))
    else:
        text = line.replace("  ", " ")
        style = styles["meta"] if text.startswith("**Période") or text.startswith("**Périmètre") else styles["body"]
        story.append(Paragraph(inline(text), style))

doc = SimpleDocTemplate(str(OUTPUT), pagesize=A4, rightMargin=20 * mm,
                        leftMargin=20 * mm, topMargin=19 * mm, bottomMargin=23 * mm,
                        title="Rapport d’activité Sendra 19 au 23 octobre 2026",
                        author="Projet Sendra")
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUTPUT)
