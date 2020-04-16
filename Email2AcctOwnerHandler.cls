public without sharing class Email2AcctOwnerHandler {

    /*
    * Trigger para realizar envio de e-mail para o Account Owner
    * Realiza o envio de e-mail pela plataforma com texto simples
    * A trigger é disparada assim que um CC Order no B2B é criado
    */

    public static void handle(final List<ccrz__E_Order__c> ccOrders) {
        for(ccrz__E_Order__c ccOrder: ccOrders) {
            executeSendMail(ccOrder);
        }
    }
    
    public static void executeSendMail(final ccrz__E_Order__c ccOrder) {
        String emailOwner, orderId, emailComprador, poNumber, nomeComprador, 
            sobrenomeComprador, acctNome, nomeVendedor, shipping, bodyItems, replyTo, senderDisplayName, subject;
        Double totalShipping, originatedCartId;
        
        orderId = ccOrder.id;
        emailComprador = ccOrder.ccrz__BuyerEmail__c;
        nomeComprador = ccOrder.ccrz__BuyerFirstName__c;
        sobrenomeComprador = ccOrder.ccrz__BuyerLastName__c;
        shipping = ccOrder.ccrz__ShipMethod__c;
        totalShipping = ccOrder.ccrz__ShipAmount__c;
        
        final Account account = getAccount(ccOrder.ccrz__Account__c);
        acctNome = account.Name;
        final User user = getUser(account.OwnerId);
        
        if(user != null){
            emailOwner = user.Email;
            nomeVendedor = user.Name;
        }else{
            
        }
        
        final Id cartId = ccOrder.ccrz__OriginatedCart__c;
        
        bodyItems = setEmailBody(orderId, emailComprador, poNumber, 
                     nomeComprador, sobrenomeComprador, acctNome, nomeVendedor, 
                     shipping, totalShipping, originatedCartId, cartId);
        
        replyTo = 'renan.catto@gmail.com';
        senderDisplayName = 'Renan Cassaro Catto';
        subject = 'Nova venda realizada em nosso B2B!';

        sendMail(emailOwner, bodyItems, replyTo, senderDisplayName, subject);
           
    }
    
 
    
    public static String setEmailBody(String orderId, String emailComprador, String poNumber, String nomeComprador, 
                                      String sobrenomeComprador, String acctNome, String nomeVendedor, String shipping, 
                                      Double totalShipping, Double originatedCartId, Id cartId)
    {
        
        List<ccrz__E_CartItem__c> cartItems = [
            SELECT Id, ccrz__Product__c, ccrz__Quantity__c, ccrz__ItemTotal__c
            FROM ccrz__E_CartItem__c 
            WHERE ccrz__Cart__c =: cartId
        ];
        
        String body = 'Olá, ' + nomeVendedor + '! A conta ' + acctNome + ' fechou uma venda em nosso B2B!<br/>';
        
        body += 'OrderId: ' + orderId + '<br/>';
        body += 'Nome do Comprador: ' + nomeComprador + '  ' + sobrenomeComprador + '<br/>';
        body += 'Email para Contato: ' + emailComprador + '<br/>';
        body += '--------------------------------------------<br/>';
        Double total = 0.0;                                
        for(ccrz__E_CartItem__c cartItem : cartItems){
            Double qty = cartItem.ccrz__Quantity__c;
            Double itemTotal = cartItem.ccrz__ItemTotal__c;
            ccrz__E_Product__c product = getProduct(cartItem.ccrz__Product__c);
            body += 'Produto: ' + product.Name + '<br/>SKU: ' + product.ccrz__SKU__c + '<br/>Quantidade: ' + qty + '<br/>';
            body += 'Total: R$' + formatDecimal(itemTotal, 2) + '</br>';
            body += '--------------------------------------------<br/>';
            total += itemTotal;
        }
        
        body += 'Valor total dos produtos: R$' + formatDecimal(total, 2) + '<br/>';
        body += '<br/>Envio escolhido: ' + shipping + '<br/>';
        body += 'Total do envio: R$' + formatDecimal(totalShipping, 2) + '<br/>';
        total = total + totalShipping;
        body += 'Total da compra + envio: R$' + formatDecimal(total, 2) + '<br/>';
        body += '<br/>Favor realizar a avaliação da compra e entrar em contato com o comprador!';
        
        return body;
    }
    
    public static void sendMail(String emailOwner, String body, String replyTo, String senderDisplayName, String subject){

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        
        sendTo.add(emailOwner);
        mail.setToAddresses(sendTo);
        mail.setReplyTo(replyTo);
        mail.setSenderDisplayName(senderDisplayName);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mails.add(mail);
        Messaging.sendEmail(mails);
    }
    
       private static ccrz__E_Product__c  getProduct(final Id productId) {
        return [
                SELECT Id, Name, ccrz__SKU__c
                FROM ccrz__E_Product__c
                WHERE Id =: productId
                LIMIT 1
              ];
    }
    
    private static Account getAccount(final Id accountId) {
        return [
                SELECT Name, Owner.Id
               	FROM Account
                WHERE Id =: accountId
                LIMIT 1
               ];
    }
    
    private static User getUser (final Id userId) {
        return [
                SELECT Name, Email
                FROM User
                WHERE Id =: userId
                LIMIT 1
               ];
    }
    
    /**
     * Useful to utility to format a decimal with specified number of decimal digits.
     * @param value to format as a string
     * @param scale number of decimal digits
     * @return the formatted string or null if value was null
     */
    
    public static String formatDecimal(Decimal value, Integer scale) {
        String retval = '';
        if(value != null) {
            if(scale == null) {
                scale = value.scale();
            }
            retval = value.format();
            if(scale <= 0) {
                retval = Decimal.valueOf(value.round()).format();
            }
            else if(scale > 0 && scale <= 18) {
                Long modulus = Long.valueOf('1000000000000000000'.left(scale+1));
                Long msd = (Math.abs(value)*modulus).round();
                Long lsd = Math.mod(msd,modulus);
                msd = ((value > 0)?(msd - lsd):(lsd - msd))/modulus;
                retval = Decimal.valueOf(msd).format()+'.'+(String.valueOf(modulus+lsd).substring(1));
            }
        }
        return retval;
    }
    
}