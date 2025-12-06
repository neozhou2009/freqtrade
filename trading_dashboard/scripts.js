// Copied from /trading_dashboard/scripts.js
// Profit Distribution Pie Chart
document.addEventListener('DOMContentLoaded', function() {
    const pieCtx = document.getElementById('profitPie').getContext('2d');
    new Chart(pieCtx, {
        type: 'pie',
        data: {
            labels: ['Profitable', 'Losses'],
            datasets: [{
                data: [75, 25],
                backgroundColor: ['#10b981', '#ef4444'],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { color: '#ffffff' }
                }
            }
        }
    });
});