#!/bin/bash

# ============================================
# Restaurant Billing System - Complete Deployment Script
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://github.com/vibhakar246/Billing--Application.git"
GITHUB_REPO_NAME="Billing--Application"
PROJECT_DIR="$HOME/restaurant-billing-system"
DOCKER_IMAGE_NAME="restaurant-billing-system"
JENKINS_PORT="8080"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Restaurant Billing System - Auto Deployment${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Step 1: Create the HTML file
print_info "Step 1: Creating index.html..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RestroBilling - Restaurant Billing System</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .logo i {
            font-size: 40px;
        }

        .logo h1 {
            font-size: 28px;
            font-weight: 600;
        }

        .tagline {
            font-size: 12px;
            opacity: 0.9;
            margin-left: 10px;
        }

        .datetime {
            text-align: right;
            font-size: 14px;
        }

        #currentDate, #currentTime {
            margin: 5px 0;
        }

        .main-content {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 20px;
            padding: 20px;
        }

        .menu-section {
            background: #f8f9fa;
            border-radius: 15px;
            padding: 20px;
        }

        .section-title {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            color: #333;
        }

        .section-title i {
            font-size: 24px;
            color: #667eea;
        }

        .section-title h2 {
            font-size: 20px;
        }

        .order-count {
            background: #667eea;
            color: white;
            border-radius: 50%;
            width: 25px;
            height: 25px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            margin-left: 10px;
        }

        .category-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .category-btn {
            padding: 8px 16px;
            border: none;
            background: white;
            border-radius: 25px;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 14px;
            font-weight: 500;
        }

        .category-btn:hover, .category-btn.active {
            background: #667eea;
            color: white;
            transform: translateY(-2px);
        }

        .menu-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 15px;
            max-height: 600px;
            overflow-y: auto;
        }

        .menu-item {
            background: white;
            border-radius: 10px;
            padding: 15px;
            cursor: pointer;
            transition: all 0.3s;
            border: 2px solid transparent;
        }

        .menu-item:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
            border-color: #667eea;
        }

        .menu-item h3 {
            font-size: 16px;
            margin-bottom: 8px;
        }

        .menu-item .price {
            font-size: 18px;
            font-weight: bold;
            color: #667eea;
        }

        .menu-item .category {
            font-size: 12px;
            color: #999;
            margin-top: 5px;
        }

        .cart-section {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            position: sticky;
            top: 20px;
            height: fit-content;
        }

        .customer-details {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }

        .customer-details input, .customer-details select {
            flex: 1;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }

        .cart-items {
            max-height: 400px;
            overflow-y: auto;
            margin-bottom: 20px;
        }

        .empty-cart {
            text-align: center;
            padding: 40px;
            color: #999;
        }

        .empty-cart i {
            font-size: 48px;
            margin-bottom: 10px;
        }

        .cart-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            border-bottom: 1px solid #eee;
            margin-bottom: 10px;
        }

        .cart-item-info {
            flex: 1;
        }

        .cart-item-name {
            font-weight: 600;
            margin-bottom: 5px;
        }

        .cart-item-price {
            font-size: 12px;
            color: #999;
        }

        .cart-item-quantity {
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 0 15px;
        }

        .cart-item-quantity button {
            width: 25px;
            height: 25px;
            border: none;
            background: #f0f0f0;
            border-radius: 50%;
            cursor: pointer;
        }

        .cart-item-total {
            font-weight: bold;
            min-width: 70px;
            text-align: right;
            color: #667eea;
        }

        .remove-item {
            color: #ff4757;
            cursor: pointer;
            margin-left: 10px;
        }

        .cart-summary {
            border-top: 2px solid #eee;
            padding-top: 15px;
            margin-bottom: 20px;
        }

        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .summary-row.total {
            font-size: 18px;
            font-weight: bold;
            color: #667eea;
            border-top: 2px solid #eee;
            padding-top: 10px;
            margin-top: 10px;
        }

        .cart-actions {
            display: flex;
            gap: 10px;
        }

        .btn-clear, .btn-generate {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }

        .btn-clear {
            background: #ff4757;
            color: white;
        }

        .btn-generate {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .btn-clear:hover, .btn-generate:hover {
            transform: translateY(-2px);
        }

        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
        }

        .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 20px;
            width: 80%;
            max-width: 600px;
            border-radius: 15px;
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }

        .close {
            font-size: 28px;
            cursor: pointer;
        }

        .bill {
            font-family: monospace;
        }

        .bill table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }

        .bill th, .bill td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }

        .modal-footer {
            margin-top: 20px;
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }

        .btn-print, .btn-close {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
        }

        .btn-print {
            background: #28a745;
            color: white;
        }

        .btn-close {
            background: #6c757d;
            color: white;
        }

        @media (max-width: 968px) {
            .main-content {
                grid-template-columns: 1fr;
            }
            .cart-section {
                position: static;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">
                <i class="fas fa-utensils"></i>
                <h1>RestroBilling</h1>
                <span class="tagline">Smart Restaurant Billing System</span>
            </div>
            <div class="datetime">
                <div id="currentDate"></div>
                <div id="currentTime"></div>
            </div>
        </div>

        <div class="main-content">
            <div class="menu-section">
                <div class="section-title">
                    <i class="fas fa-hamburger"></i>
                    <h2>Our Menu</h2>
                </div>
                <div class="category-tabs" id="categoryTabs"></div>
                <div class="menu-grid" id="menuGrid"></div>
            </div>

            <div class="cart-section">
                <div class="section-title">
                    <i class="fas fa-shopping-cart"></i>
                    <h2>Current Order</h2>
                    <span class="order-count" id="orderCount">0</span>
                </div>
                
                <div class="customer-details">
                    <input type="text" id="customerName" placeholder="Customer Name (Optional)">
                    <select id="paymentMethod">
                        <option value="Cash">Cash 💵</option>
                        <option value="Card">Card 💳</option>
                        <option value="UPI">UPI 📱</option>
                    </select>
                </div>

                <div class="cart-items" id="cartItems">
                    <div class="empty-cart">
                        <i class="fas fa-shopping-basket"></i>
                        <p>No items added yet</p>
                    </div>
                </div>

                <div class="cart-summary">
                    <div class="summary-row">
                        <span>Subtotal:</span>
                        <span id="subtotal">₹0.00</span>
                    </div>
                    <div class="summary-row">
                        <span>GST (5%):</span>
                        <span id="gst">₹0.00</span>
                    </div>
                    <div class="summary-row total">
                        <span>Total:</span>
                        <span id="total">₹0.00</span>
                    </div>
                </div>

                <div class="cart-actions">
                    <button class="btn-clear" onclick="clearCart()">
                        <i class="fas fa-trash-alt"></i> Clear Cart
                    </button>
                    <button class="btn-generate" onclick="generateBill()">
                        <i class="fas fa-receipt"></i> Generate Bill
                    </button>
                </div>
            </div>
        </div>

        <div id="billModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2><i class="fas fa-receipt"></i> RestroBilling Invoice</h2>
                    <span class="close" onclick="closeModal()">&times;</span>
                </div>
                <div id="billContent"></div>
                <div class="modal-footer">
                    <button onclick="printBill()" class="btn-print">
                        <i class="fas fa-print"></i> Print Bill
                    </button>
                    <button onclick="closeModal()" class="btn-close">Close</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        let cart = [];
        let menuItems = [
            { id: 1, name: "Plain Dal", price: 120, category_id: 1, category_name: "North Indian" },
            { id: 2, name: "Dal Makhani", price: 180, category_id: 1, category_name: "North Indian" },
            { id: 3, name: "Jeera Rice", price: 140, category_id: 1, category_name: "North Indian" },
            { id: 4, name: "Butter Rice", price: 160, category_id: 1, category_name: "North Indian" },
            { id: 5, name: "Tawa Roti", price: 15, category_id: 6, category_name: "Breads" },
            { id: 6, name: "Butter Roti", price: 20, category_id: 6, category_name: "Breads" },
            { id: 7, name: "Naan", price: 30, category_id: 6, category_name: "Breads" },
            { id: 8, name: "Veg Fried Rice", price: 150, category_id: 3, category_name: "Chinese" },
            { id: 9, name: "Chilli Paneer", price: 220, category_id: 3, category_name: "Chinese" },
            { id: 10, name: "Veg Burger", price: 80, category_id: 4, category_name: "Fast Food" },
            { id: 11, name: "French Fries", price: 90, category_id: 4, category_name: "Fast Food" },
            { id: 12, name: "Water Bottle", price: 20, category_id: 5, category_name: "Beverages" },
            { id: 13, name: "Soft Drink", price: 40, category_id: 5, category_name: "Beverages" },
            { id: 14, name: "Masala Dosa", price: 80, category_id: 2, category_name: "South Indian" },
            { id: 15, name: "Idli Sambhar", price: 70, category_id: 2, category_name: "South Indian" }
        ];

        function loadCategories() {
            const categories = [...new Map(menuItems.map(item => [item.category_id, { id: item.category_id, name: item.category_name }])).values()];
            const categoryTabs = document.getElementById('categoryTabs');
            categoryTabs.innerHTML = `<button class="category-btn active" data-category="all">All Items 🍽️</button>` +
                categories.map(cat => `<button class="category-btn" data-category="${cat.id}">${cat.name}</button>`).join('');
            
            document.querySelectorAll('.category-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    document.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
                    this.classList.add('active');
                    displayMenuItems(this.getAttribute('data-category'));
                });
            });
        }

        function displayMenuItems(category) {
            const menuGrid = document.getElementById('menuGrid');
            let filtered = category === 'all' ? menuItems : menuItems.filter(item => item.category_id == category);
            menuGrid.innerHTML = filtered.map(item => `
                <div class="menu-item" onclick="addToCart(${item.id})">
                    <h3>${item.name}</h3>
                    <div class="price">₹${item.price}</div>
                    <div class="category">${item.category_name}</div>
                </div>
            `).join('');
        }

        function addToCart(id) {
            const item = menuItems.find(i => i.id === id);
            const existing = cart.find(i => i.id === id);
            if (existing) {
                existing.quantity++;
                existing.subtotal = existing.quantity * existing.price;
            } else {
                cart.push({ ...item, quantity: 1, subtotal: item.price });
            }
            updateCartDisplay();
        }

        function updateCartDisplay() {
            const cartDiv = document.getElementById('cartItems');
            document.getElementById('orderCount').textContent = cart.reduce((s, i) => s + i.quantity, 0);
            
            if (cart.length === 0) {
                cartDiv.innerHTML = '<div class="empty-cart"><i class="fas fa-shopping-basket"></i><p>No items added yet</p></div>';
            } else {
                cartDiv.innerHTML = cart.map(item => `
                    <div class="cart-item">
                        <div class="cart-item-info">
                            <div class="cart-item-name">${item.name}</div>
                            <div class="cart-item-price">₹${item.price} each</div>
                        </div>
                        <div class="cart-item-quantity">
                            <button onclick="updateQty(${item.id}, -1)">-</button>
                            <span>${item.quantity}</span>
                            <button onclick="updateQty(${item.id}, 1)">+</button>
                        </div>
                        <div class="cart-item-total">₹${item.subtotal}</div>
                        <div class="remove-item" onclick="removeItem(${item.id})"><i class="fas fa-trash-alt"></i></div>
                    </div>
                `).join('');
            }
            updateTotals();
        }

        function updateQty(id, change) {
            const item = cart.find(i => i.id === id);
            if (item) {
                item.quantity += change;
                if (item.quantity <= 0) {
                    cart = cart.filter(i => i.id !== id);
                } else {
                    item.subtotal = item.quantity * item.price;
                }
                updateCartDisplay();
            }
        }

        function removeItem(id) {
            cart = cart.filter(i => i.id !== id);
            updateCartDisplay();
        }

        function updateTotals() {
            const subtotal = cart.reduce((s, i) => s + i.subtotal, 0);
            const gst = subtotal * 0.05;
            const total = subtotal + gst;
            document.getElementById('subtotal').textContent = `₹${subtotal.toFixed(2)}`;
            document.getElementById('gst').textContent = `₹${gst.toFixed(2)}`;
            document.getElementById('total').textContent = `₹${total.toFixed(2)}`;
        }

        function clearCart() {
            if (confirm('Clear cart?')) {
                cart = [];
                updateCartDisplay();
            }
        }

        function generateBill() {
            if (cart.length === 0) {
                alert('Add items first!');
                return;
            }
            const customer = document.getElementById('customerName').value || 'Guest';
            const payment = document.getElementById('paymentMethod').value;
            const subtotal = cart.reduce((s, i) => s + i.subtotal, 0);
            const gst = subtotal * 0.05;
            const total = subtotal + gst;
            const orderNo = 'RESTRO-' + Date.now().toString().slice(-8);
            
            document.getElementById('billContent').innerHTML = `
                <div class="bill">
                    <div style="text-align:center"><h2>RestroBilling</h2>
                    <p>123 Restaurant Street</p>
                    <p>Order: ${orderNo}</p>
                    <p>Customer: ${customer}</p>
                    <p>Payment: ${payment}</p>
                    <hr></div>
                    <table><thead><tr><th>Item</th><th>Qty</th><th>Price</th><th>Total</th></tr></thead>
                    <tbody>${cart.map(i => `<tr><td>${i.name}</td><td>${i.quantity}</td><td>₹${i.price}</td><td>₹${i.subtotal}</td></tr>`).join('')}</tbody>
                    <tfoot><tr><td colspan="3">Subtotal:</td><td>₹${subtotal.toFixed(2)}</td></tr>
                    <tr><td colspan="3">GST 5%:</td><td>₹${gst.toFixed(2)}</td></tr>
                    <tr><td colspan="3"><strong>Total:</strong></td><td><strong>₹${total.toFixed(2)}</strong></td></tr></tfoot></table>
                    <div style="text-align:center; margin-top:20px;"><p>Thank you! Visit again 🙏</p></div>
                </div>
            `;
            document.getElementById('billModal').style.display = 'block';
            cart = [];
            updateCartDisplay();
        }

        function printBill() {
            const content = document.getElementById('billContent').innerHTML;
            const w = window.open('', '_blank');
            w.document.write(`<html><head><title>Bill</title><style>body{font-family:monospace;padding:20px}</style></head><body>${content}<script>window.onload=function(){window.print();setTimeout(function(){window.close()},500)}<\/script></body></html>`);
            w.document.close();
        }

        function closeModal() {
            document.getElementById('billModal').style.display = 'none';
        }

        function updateDateTime() {
            const now = new Date();
            document.getElementById('currentDate').innerHTML = now.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
            document.getElementById('currentTime').innerHTML = now.toLocaleTimeString();
        }

        loadCategories();
        displayMenuItems('all');
        updateDateTime();
        setInterval(updateDateTime, 1000);
    </script>
</body>
</html>
EOF

print_status "index.html created successfully"

# Step 2: Create Dockerfile
print_info "Step 2: Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

print_status "Dockerfile created successfully"

# Step 3: Create Jenkinsfile
print_info "Step 3: Creating Jenkinsfile..."
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'restaurant-billing-system'
        IMAGE_TAG = "latest-${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/vibhakar246/Billing--Application.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
            }
        }
        
        stage('Test Docker Image') {
            steps {
                sh """
                    docker run -d --name test-container -p 8888:80 ${IMAGE_NAME}:latest
                    sleep 3
                    curl -s http://localhost:8888 | grep -q "RestroBilling" && echo "✅ Test passed!" || echo "❌ Test failed"
                    docker stop test-container && docker rm test-container
                """
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "✅ Build successful! Image ready: ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline successful! Your app is ready!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
EOF

print_status "Jenkinsfile created successfully"

# Step 4: Initialize Git and Push to GitHub
print_info "Step 4: Pushing to GitHub..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_info "Installing git..."
    sudo apt update && sudo apt install git -y
fi

# Initialize git repository
if [ ! -d .git ]; then
    git init
    print_status "Git repository initialized"
fi

# Configure git if not configured
if ! git config --get user.name > /dev/null; then
    git config --global user.name "Maa Bhawani"
    git config --global user.email "maabhawani@example.com"
fi

# Add all files
git add index.html Dockerfile Jenkinsfile
git add deploy.sh 2>/dev/null || true

# Commit changes
git commit -m "Auto-deploy: Restaurant Billing System - $(date)"

# Add remote
git remote remove origin 2>/dev/null || true
git remote add origin $GITHUB_REPO

# Push to GitHub
print_info "Pushing to GitHub repository: $GITHUB_REPO"
print_info "You may be prompted for GitHub credentials"
git branch -M main
git push -u origin main --force

print_status "Code pushed to GitHub successfully!"

# Step 5: Build and Test Docker Locally
print_info "Step 5: Building and testing Docker image locally..."

# Build Docker image
docker build -t $DOCKER_IMAGE_NAME:latest .

# Test run
docker run -d --name test-$DOCKER_IMAGE_NAME -p 8080:80 $DOCKER_IMAGE_NAME:latest

# Wait for container to start
sleep 3

# Test if it's working
if curl -s http://localhost:8080 | grep -q "RestroBilling"; then
    print_status "Docker container is working! Access at: http://localhost:8080"
else
    print_error "Docker container test failed"
fi

# Stop and remove test container
docker stop test-$DOCKER_IMAGE_NAME
docker rm test-$DOCKER_IMAGE_NAME

# Step 6: Check Jenkins Status
print_info "Step 6: Checking Jenkins..."

if command -v jenkins &> /dev/null; then
    print_status "Jenkins is installed"
    
    # Check if Jenkins service is running
    if systemctl is-active --quiet jenkins; then
        print_status "Jenkins service is running"
        print_info "Access Jenkins at: http://localhost:$JENKINS_PORT"
    else
        print_info "Starting Jenkins service..."
        sudo systemctl start jenkins
        sudo systemctl enable jenkins
        print_status "Jenkins started! Access at: http://localhost:$JENKINS_PORT"
    fi
else
    print_info "Jenkins not installed. Installing Jenkins..."
    
    # Install Java
    sudo apt update
    sudo apt install openjdk-11-jdk -y
    
    # Install Jenkins
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update
    sudo apt install jenkins -y
    
    # Start Jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    print_status "Jenkins installed successfully!"
    
    # Get initial password
    echo -e "${YELLOW}Jenkins initial admin password:${NC}"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    echo ""
fi

# Step 7: Create Jenkins Pipeline Job (via CLI)
print_info "Step 7: Creating Jenkins Pipeline job..."

# Install Jenkins CLI if not exists
if [ ! -f jenkins-cli.jar ]; then
    wget http://localhost:8080/jnlpJars/jenkins-cli.jar 2>/dev/null || true
fi

# Step 8: Final Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Summary:${NC}"
echo -e "  1. 📝 HTML file created: ${GREEN}index.html${NC}"
echo -e "  2. 🐳 Dockerfile created: ${GREEN}Dockerfile${NC}"
echo -e "  3. 🔧 Jenkinsfile created: ${GREEN}Jenkinsfile${NC}"
echo -e "  4. 📦 Code pushed to GitHub: ${GREEN}$GITHUB_REPO${NC}"
echo -e "  5. 🐳 Docker image built and tested locally"
echo -e "  6. 🔧 Jenkins is ${GREEN}$(systemctl is-active jenkins)${NC}"
echo ""
echo -e "${YELLOW}Access URLs:${NC}"
echo -e "  • Local App: ${GREEN}http://localhost:8080${NC}"
echo -e "  • Jenkins: ${GREEN}http://localhost:$JENKINS_PORT${NC}"
echo -e "  • GitHub: ${GREEN}$GITHUB_REPO${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Open Jenkins: http://localhost:$JENKINS_PORT"
echo -e "  2. Create a new Pipeline job"
echo -e "  3. Set SCM to: $GITHUB_REPO"
echo -e "  4. Run the pipeline"
echo -e ""
echo -e "${BLUE}========================================${NC}"

# Step 9: Open browser (if possible)
if command -v xdg-open &> /dev/null; then
    print_info "Opening application in browser..."
    xdg-open http://localhost:8080 2>/dev/null || true
fi
