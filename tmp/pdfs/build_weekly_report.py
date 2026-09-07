from pathlib import Path
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageTemplate,
    Paragraph,
    Spacer,
    HRFlowable,
    KeepTogether,
)

ROOT = Path(r"C:\Projets\sendrapp\sendra")
SOURCE = ROOT / "RAPPORT_SEMAINE 31 août au 4 septembre"
OUTPUT = ROOT / "output" / "pdf" / "Rapport_Sendra_31_aout_4_septembre_2026.pdf"

pdfmetrics.registerFont(TTFont("Arial", r"C:\Windows\Fonts\arial.ttf"))
pdfmetrics.registerFont(TTFont("ArialBold", r"C:\Windows\Fonts\arialbd.ttf"))
pdfmetrics.registerFontFamily("Arial", normal="Arial", bold="ArialBold")

GREEN = colors.HexColor("#078C48")
DARK = colors.HexColor("#17211C")
MUTED = colors.HexColor("#63706A")
LIGHT = colors.HexColor("#EDF6F1")


def inline_markup(text: str) -> str:
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"`([^`]+)`", r'<font name="Courier">\1</font>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", text)
    return text


styles = getSampleStyleSheet()
base = ParagraphStyle(
    "Body",
    parent=styles["BodyText"],
    fontName="Arial",
    fontSize=9.3,
    leading=13.2,
    textColor=DARK,
    spaceAfter=5,
)
h1 = ParagraphStyle(
    "Title",
    parent=base,
    fontName="ArialBold",
    fontSize=22,
    leading=27,
    textColor=GREEN,
    alignment=TA_CENTER,
    spaceAfter=10,
)
h2 = ParagraphStyle(
    "H2",
    parent=base,
    fontName="ArialBold",
    fontSize=14,
    leading=18,
    textColor=GREEN,
    spaceBefore=12,
    spaceAfter=7,
    keepWithNext=True,
)
h3 = ParagraphStyle(
    "H3",
    parent=base,
    fontName="ArialBold",
    fontSize=11.3,
    leading=15,
    textColor=DARK,
    spaceBefore=8,
    spaceAfter=5,
    keepWithNext=True,
)
bullet = ParagraphStyle(
    "Bullet",
    parent=base,
    leftIndent=13,
    firstLineIndent=-8,
    bulletIndent=2,
    spaceAfter=4,
)
numbered = ParagraphStyle("Numbered", parent=bullet)
meta = ParagraphStyle(
    "Meta",
    parent=base,
    fontSize=9.5,
    leading=14,
    backColor=LIGHT,
    borderColor=colors.HexColor("#CFE6D9"),
    borderWidth=0.7,
    borderPadding=8,
    spaceAfter=8,
)


def header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setStrokeColor(colors.HexColor("#D8E3DD"))
    canvas.line(18 * mm, h - 15 * mm, w - 18 * mm, h - 15 * mm)
    canvas.setFont("ArialBold", 8)
    canvas.setFillColor(GREEN)
    canvas.drawString(18 * mm, h - 11.5 * mm, "SENDRA")
    canvas.setFont("Arial", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawRightString(w - 18 * mm, h - 11.5 * mm, "Rapport d'activité - 31 août au 4 septembre 2026")
    canvas.line(18 * mm, 14 * mm, w - 18 * mm, 14 * mm)
    canvas.drawString(18 * mm, 9.5 * mm, "Plateforme Sendra - Rapport hebdomadaire")
    canvas.drawRightString(w - 18 * mm, 9.5 * mm, f"Page {doc.page}")
    canvas.restoreState()


doc = BaseDocTemplate(
    str(OUTPUT),
    pagesize=A4,
    rightMargin=18 * mm,
    leftMargin=18 * mm,
    topMargin=21 * mm,
    bottomMargin=19 * mm,
    title="Rapport d'activité - Plateforme Sendra",
    author="Équipe Sendra",
)
frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="body")
doc.addPageTemplates([PageTemplate(id="report", frames=[frame], onPageEnd=header_footer)])

lines = SOURCE.read_text(encoding="utf-8").splitlines()
story = []
paragraph_buffer = []
meta_buffer = []


def flush_paragraph():
    if paragraph_buffer:
        story.append(Paragraph(inline_markup(" ".join(paragraph_buffer)), base))
        paragraph_buffer.clear()


for line in lines:
    stripped = line.strip()
    if not stripped:
        flush_paragraph()
        if meta_buffer:
            story.append(Paragraph("<br/>".join(meta_buffer), meta))
            meta_buffer.clear()
        continue
    if stripped == "---":
        flush_paragraph()
        story.append(Spacer(1, 3))
        story.append(HRFlowable(width="100%", thickness=0.7, color=colors.HexColor("#D8E3DD")))
        story.append(Spacer(1, 3))
        continue
    if stripped.startswith("# "):
        flush_paragraph()
        story.append(Spacer(1, 8))
        story.append(Paragraph(inline_markup(stripped[2:]), h1))
        continue
    if stripped.startswith("## "):
        flush_paragraph()
        story.append(Paragraph(inline_markup(stripped[3:]), h2))
        continue
    if stripped.startswith("### "):
        flush_paragraph()
        story.append(Paragraph(inline_markup(stripped[4:]), h3))
        continue
    if stripped.startswith("**Période") or stripped.startswith("**Périmètre"):
        flush_paragraph()
        meta_buffer.append(inline_markup(stripped))
        continue
    match = re.match(r"^-\s+(.*)$", stripped)
    if match:
        flush_paragraph()
        story.append(Paragraph(inline_markup(match.group(1)), bullet, bulletText="•"))
        story.append(Spacer(1, 1.5))
        continue
    match = re.match(r"^(\d+)\.\s+(.*)$", stripped)
    if match:
        flush_paragraph()
        story.append(Paragraph(inline_markup(match.group(2)), numbered, bulletText=match.group(1) + "."))
        story.append(Spacer(1, 1.5))
        continue
    paragraph_buffer.append(stripped)

flush_paragraph()
if meta_buffer:
    story.append(Paragraph("<br/>".join(meta_buffer), meta))

doc.build(story)
print(OUTPUT)
