local Translations = {
    error = {
        negative = 'Trying to sell a negative amount?',
        no_melt = 'You didn\'t give me anything to melt...',
        no_items = 'Not enough items',
        inventory_full = 'Inventory too full to receive all possible items. Try making sure inventory isn\'t full next time. Items Lost: %{value}',
        
    },
    success = {
        sold = 'You have sold %{value} x %{value2} for $%{value3}',
        items_received = 'You received %{value} x %{value2}',
        smelt_started = 'You have started melting %{item} x %{amount}',
    },
    info = {
        title = 'Pawn Shop',
        subject = 'Melting Items',
        message = 'We finished melting your items. You can come pick them up at any time.',
        open_pawn = 'Open the Pawn Shop',
        sell = 'Sell Items',
        sell_pawn = 'Sell Items To The Pawn Shop',
        melt = 'Melt Items',
        melt_pawn = 'Open the Melting Shop',
        melt_pickup = 'Pickup Melted Items',
        pawn_closed = 'Pawnshop is closed. Come back between %{value}:00 AM - %{value2}:00 PM',
        sell_items = 'Selling Price $%{value}',
        back = '⬅ Go Back',
        melt_item = 'Melt %{value}',
        max = 'Max Amount %{value}',
        submit = 'Melt',
        melt_wait = 'Give me %{value} minutes and I\'ll have your stuff melted',
        already_melt = 'We Need More Time! Check Your Email For How Much Longer We Need',
    },
    email = {
        sender = 'Pawn Shop',
        subject = 'New Items',
        message = 'Thank You For Trusting Us With Your Items. Here Is A List Of The Items You Gave Us:  <br / >  Item: %{item}  | Amount: %{amount}  <br / >  <br / > Your Order Will Be Ready In %{time} Minutes. <br / > <br / >  Thank You For Choosing Us. <br / > <br / >  Pawn Shop',
        message2 = 'Thank You For Trusting Us With Your Items. <br /> <br /> You have %{time} minutes to pick up your items. <br /> <br /> Thank You For Choosing Us. <br /> <br /> Pawn Shop',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
