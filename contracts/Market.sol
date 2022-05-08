//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

contract Market {
    // Contains global store data
    uint256 taxFee;
    address immutable taxAccount;
    uint8 totalSupply = 0;

    // Specifies product information
    struct ProductStruct {
        uint8 id;
        address seller;
        string title;
        string description;
        string brand;
        uint256 cost;
        uint256 timestamp;
    }

    // Associates products with sellers and buyers
    ProductStruct[] products;
    mapping(address => ProductStruct[]) productsOf;
    mapping(uint8 => address) public sellerOf;
    mapping(uint8 => bool) productExists;

    // Logs out sales record
    event Sale(
        uint8 id,
        address indexed buyer,
        address indexed seller,
        uint256 cost,
        uint256 timestamp
    );
    
    // Logs out created product record
    event Created(
        uint8 id,
        address indexed seller,
        uint256 timestamp
    );

    // Initializes tax on product sale
    constructor(uint256 _taxFee) {
        taxAccount = msg.sender;
        taxFee = _taxFee;
    }

    // Performs product creation
    function createProduct(
        string memory title, 
        string memory description, 
        string memory brand, 
        uint256 cost
    ) public returns (bool) {
        require(bytes(title).length > 0, "Title empty");
        require(bytes(description).length > 0, "Description empty");
        require(bytes(brand).length > 0, "Brand empty");
        require(cost > 0 ether, "Price cannot be zero");

        // Adds product to shop
        products.push(
            ProductStruct(
                totalSupply++,
                msg.sender,
                title,
                description,
                brand,
                cost,
                block.timestamp
            )
        );

        // Records product selling detail
        sellerOf[totalSupply] = msg.sender;
        productExists[totalSupply] = true;

        emit Created(
            totalSupply,
            msg.sender,
            block.timestamp
        );

        return true;
    }

    // Performs product payment
    function payForProduct(uint8 id)
        public payable returns (bool) {
        require(productExists[id], "Product does not exist");
        require(msg.value >= products[id - 1].cost, "Ethers too small");

        // Computes payment data
        address seller = sellerOf[id];
        uint256 tax = (msg.value / 100) * taxFee;
        uint256 payment = msg.value - tax;

        // Bills buyer on product sale
        payTo(seller, payment);
        payTo(taxAccount, tax);

        // Gives product to buyer
        productsOf[msg.sender].push(products[id - 1]);

        emit Sale(
            id,
            msg.sender,
            seller,
            payment,
            block.timestamp
        );
        
        return true;
    }
    
    // The transferTo function
    function transferTo(
        address to,
        uint256 amount
    ) internal returns (bool) {
        payable(to).transfer(amount);
        return true;
    }
    
    // The sendTo function
    function sendTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        require(payable(to).send(amount), "Payment failed");
        return true;
    }

    // The payTo function
    function payTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }

    // Returns products of buyer
    function myProducts(address buyer)
        external view returns (ProductStruct[] memory) {
        return productsOf[buyer];
    }
    
    // Returns products in store
    function getProducts()
        external view returns (ProductStruct[] memory) {
        return products;
    }
    
    // Returns a specific product by id
    function getProduct(uint8 id)
        external view returns (ProductStruct memory) {
        return products[id - 1];
    }
}