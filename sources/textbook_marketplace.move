module MyModule::TextbookMarketplace {

    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing a tokenized textbook NFT
    struct Textbook has store, key {
        price: u64,           // Current sale price
        creator: address,     // Original author/school address for royalties
        royalty_rate: u64,    // Royalty percentage (e.g., 10 for 10%)
    }

    /// Function to create/mint a new textbook NFT with royalty settings
    public fun create_textbook(creator: &signer, price: u64, royalty_rate: u64) {
        let textbook = Textbook {
            price,
            creator: signer::address_of(creator),
            royalty_rate,
        };
        move_to(creator, textbook);
    }

    /// Function to buy/resell textbook with automatic royalty distribution
    public fun buy_textbook(buyer: &signer, seller: address, new_price: u64) acquires Textbook {
        let textbook = borrow_global_mut<Textbook>(seller);
        
        // Calculate royalty amount for original creator
        let royalty_amount = (textbook.price * textbook.royalty_rate) / 100;
        let seller_amount = textbook.price - royalty_amount;
        
        // Transfer total payment from buyer
        let payment = coin::withdraw<AptosCoin>(buyer, textbook.price);
        
        // Split payment: royalty to original creator, rest to current seller
        let royalty = coin::extract(&mut payment, royalty_amount);
        coin::deposit<AptosCoin>(textbook.creator, royalty);
        coin::deposit<AptosCoin>(seller, payment);
        
        // Update price for next resale and transfer ownership
        textbook.price = new_price;
        let textbook_resource = move_from<Textbook>(seller);
        move_to(buyer, textbook_resource);
    }
}
