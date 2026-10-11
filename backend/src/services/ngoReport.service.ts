import PDFDocument from 'pdfkit';
import { getImpactAnalytics, getVolunteerActivityAnalytics } from './ngoImpact.service';

type ImpactData = Awaited<ReturnType<typeof getImpactAnalytics>>;
type VolunteerData = Awaited<ReturnType<typeof getVolunteerActivityAnalytics>>;

export interface ReportSection {
    title: string;
    rows: Array<[string, string | number]>;
}

export interface ImpactReport {
    title: string;
    generatedAt: string;
    note: string;
    sections: ReportSection[];
}

const formatNumber = (value: number): string =>
    Number.isInteger(value) ? String(value) : value.toFixed(2);

const quantityRows = (values: Record<string, number>): Array<[string, string]> =>
    Object.entries(values).map(([unit, value]) => [unit, formatNumber(value)]);

/** Pure builder so the report layout can be tested without a database. */
export const createImpactReport = (
    impact: ImpactData,
    volunteers: VolunteerData,
    generatedAt: Date = new Date()
): ImpactReport => ({
    title: 'Community Impact Report',
    generatedAt: generatedAt.toISOString(),
    note: impact.dataAvailability.note,
    sections: ([
        {
            title: 'Platform Summary',
            rows: [
                ['Total donations', impact.summary.totalDonations],
                ['Approved or available donations', impact.summary.approvedDonations],
                ['Total food requests', impact.summary.totalRequests],
                ['Approved food requests', impact.summary.approvedRequests],
                ['Suitable matches found', impact.summary.suitableMatches],
                ['Accepted matches', impact.summary.acceptedMatches],
                ['Completed deliveries', impact.summary.completedDeliveries],
                ['Meals delivered (estimated)', impact.summary.mealsDelivered],
                ['Food waste prevented (KG)', formatNumber(impact.summary.foodWastePreventedByUnit.KG)],
                ['Active volunteers', impact.summary.activeVolunteers]
            ]
        },
        {
            title: 'Donations by Status',
            rows: Object.entries(impact.donationStatistics.byStatus)
                .map(([status, count]): [string, number] => [status, count])
        },
        {
            title: 'Donated Quantity by Unit',
            rows: quantityRows(impact.summary.donatedQuantityByUnit)
        },
        {
            title: 'Donations by Category',
            rows: impact.donationsByCategory.map(
                (item): [string, number] => [item.category, item.count]
            )
        },
        {
            title: 'Monthly Activity (Donations / Requests)',
            rows: impact.monthlyImpact.map(
                (item): [string, string] => [item.month, `${item.donations} / ${item.requests}`]
            )
        },
        {
            title: 'Volunteer Activity',
            rows: [
                ['Volunteers on the platform', volunteers.totalVolunteers],
                ['Currently available', volunteers.availableVolunteers],
                ['Assigned deliveries', volunteers.totalAssignedDeliveries],
                ['Completed deliveries', volunteers.completedDeliveries],
                ['Active deliveries', volunteers.activeDeliveries]
            ]
        },
        {
            title: 'Top Volunteers (completed / total deliveries)',
            rows: volunteers.volunteers.slice(0, 10).map(
                (item): [string, string] => [
                    item.volunteerId,
                    `${item.completedDeliveries} / ${item.totalDeliveries}`
                ]
            )
        }
    ] as ReportSection[]).filter((section) => section.rows.length > 0)
});

export const buildImpactReport = async (): Promise<ImpactReport> => {
    const [impact, volunteers] = await Promise.all([
        getImpactAnalytics(),
        getVolunteerActivityAnalytics()
    ]);
    return createImpactReport(impact, volunteers);
};

// Category names are user-supplied; neutralise spreadsheet formulas.
const csvCell = (value: string | number): string => {
    let text = String(value);
    if (/^[=+\-@\t\r]/.test(text)) text = `'${text}`;
    return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
};

export const reportToCsv = (report: ImpactReport): string => {
    const lines: string[] = [
        [report.title, '', ''].map(csvCell).join(','),
        ['Generated at', report.generatedAt, ''].map(csvCell).join(','),
        ['Note', report.note, ''].map(csvCell).join(','),
        '',
        'Section,Metric,Value'
    ];
    for (const section of report.sections) {
        for (const [metric, value] of section.rows) {
            lines.push([section.title, metric, value].map(csvCell).join(','));
        }
    }
    // BOM lets Excel open the file as UTF-8.
    return `\uFEFF${lines.join('\r\n')}\r\n`;
};

export const reportToPdf = (report: ImpactReport): Promise<Buffer> =>
    new Promise((resolve, reject) => {
        const doc = new PDFDocument({ size: 'A4', margin: 50 });
        const chunks: Buffer[] = [];
        doc.on('data', (chunk: Buffer) => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const contentWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right;
        const ensureSpace = (height: number) => {
            if (doc.y + height > doc.page.height - doc.page.margins.bottom) doc.addPage();
        };

        doc.fillColor('#1F8F4C').fontSize(22).font('Helvetica-Bold').text(report.title);
        doc.moveDown(0.3);
        doc.fillColor('#666666').fontSize(10).font('Helvetica')
            .text(`Generated: ${new Date(report.generatedAt).toLocaleString('en-US')}`);
        doc.text(report.note);
        doc.moveDown();

        for (const section of report.sections) {
            ensureSpace(60);
            doc.fillColor('#1A1D1F').fontSize(14).font('Helvetica-Bold').text(section.title);
            doc.moveTo(doc.x, doc.y + 2).lineTo(doc.x + contentWidth, doc.y + 2)
                .strokeColor('#E7EAEC').stroke();
            doc.moveDown(0.5);

            for (const [metric, value] of section.rows) {
                ensureSpace(20);
                const rowTop = doc.y;
                doc.fillColor('#333333').fontSize(11).font('Helvetica')
                    .text(metric, doc.page.margins.left, rowTop, { width: contentWidth * 0.65 });
                const afterLabel = doc.y;
                doc.font('Helvetica-Bold').text(
                    String(value),
                    doc.page.margins.left + contentWidth * 0.65,
                    rowTop,
                    { width: contentWidth * 0.35, align: 'right' }
                );
                doc.y = Math.max(afterLabel, doc.y) + 4;
                doc.x = doc.page.margins.left;
            }
            doc.moveDown();
        }

        doc.end();
    });
