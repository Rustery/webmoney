#encoding: utf-8
module Webmoney::RequestXML    # :nodoc:all

  def xml_get_passport(opt)
    Nokogiri::XML::Builder.new { |x|
      x.request {
        x.wmid @wmid if classic?
        x.passportwmid opt[:wmid]
        x.params {
          x.dict opt[:dict] || 0
          x.info opt[:info] || 1
          x.mode opt[:mode] || 0
        }
        # unless mode == 1, signed data need'nt, but elem <sign/> required
        x.sign( (classic? && opt[:mode]) ? sign(@wmid+opt[:wmid]) : nil ) if classic?
      }
    }
  end

  def xml_bussines_level(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('WMIDLevel.request') {
        x.signerwmid @wmid
        x.wmid opt[:wmid]
      }
    }
  end

  def xml_check_sign(opt)
    plan_in, plan_out = filter_str(opt[:plan])
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.testsign {
          x.wmid opt[:wmid]
          x.plan { x.cdata plan_in }
          x.sign opt[:sign]
        }
        x.sign sign("#{@wmid}#{opt[:wmid]}#{plan_out}#{opt[:sign]}") if classic?
      }
    }
  end

  def xml_send_message(opt)
    req = reqn()
    subj_in, subj_out = filter_str(opt[:subj])
    text_in, text_out = filter_str(opt[:text])
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.reqn req
        x.message do
          x.receiverwmid opt[:wmid]
          x.msgsubj { x.cdata subj_in }
          x.msgtext { x.cdata text_in }
        end
        x.sign sign("#{opt[:wmid]}#{req}#{text_out}#{subj_out}") if classic?
      }
    }
  end

  def xml_find_wm(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.reqn req
        x.testwmpurse do
          x.wmid( opt[:wmid] || '' )
          x.purse( opt[:purse] || '' )
        end
        x.sign sign("#{opt[:wmid]}#{opt[:purse]}") if classic?
      }
    }
  end

  def xml_create_invoice(opt)
    req = reqn()
    desc_in, desc_out = filter_str(opt[:desc])
    address_in, address_out = filter_str(opt[:address])
    amount = opt[:amount].to_f.to_s.gsub(/\.?0+$/, '')
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:orderid]}#{opt[:customerwmid]}#{opt[:storepurse]}#{amount}#{desc_out}#{address_out}#{opt[:period]||0}#{opt[:expiration]||0}#{req}") if classic?
        x.invoice do
          x.orderid opt[:orderid]
          x.customerwmid opt[:customerwmid]
          x.storepurse opt[:storepurse]
          x.amount amount
          x.desc desc_in
          x.address address_in
          x.period opt[:period].to_i
          x.expiration opt[:expiration].to_i
        end
      }
    }
  end

  def xml_create_transaction(opt)
    req = reqn()
    desc_in, desc_out = filter_str(opt[:desc])                  # description
    pcode = opt[:pcode].strip if opt[:period] > 0 && opt[:pcode]
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid(@wmid)
        x.sign sign("#{req}#{opt[:transid]}#{opt[:pursesrc]}#{opt[:pursedest]}#{opt[:amount]}#{opt[:period]||0}#{pcode}#{desc_out}#{opt[:wminvid]||0}") if classic?
        x.trans {
          x.tranid opt[:transid]                      # transaction id - unique
          x.pursesrc opt[:pursesrc]                   # sender purse
          x.pursedest opt[:pursedest]                 # recipient purse
          x.amount opt[:amount]
          x.period( opt[:period] || 0 )                # protection period (0 - no protection)
          x.pcode( pcode ) if pcode  # protection code
          x.desc desc_in
          x.wminvid( opt[:wminvid] || 0 )              # invoice number (0 - without invoice)
        }
      }
    }
  end

  def xml_outgoing_invoices(opt)
    req = reqn()
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:purse]}#{req}") if classic?
        x.getoutinvoices do
          x.purse opt[:purse]
          x.wminvid opt[:wminvid]
          x.orderid opt[:orderid]
          x.datestart opt[:datestart].strftime("%Y%m%d %H:%M:%S")
          x.datefinish opt[:datefinish].strftime("%Y%m%d %H:%M:%S")
        end
      }
    }
  end

  def xml_login(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('request') {
        x.siteHolder opt[:siteHolder] || @wmid
        x.user opt[:WmLogin_WMID]
        x.ticket opt[:WmLogin_Ticket]
        x.urlId  opt[:WmLogin_UrlID]
        x.authType opt[:WmLogin_AuthType]
        x.userAddress opt[:remote_ip]
      }
    }
  end

  def xml_i_trust(opt)
    opt[:wmid] = @wmid
    xml_trust_me(opt)
  end

  def xml_trust_me(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:wmid]}#{req}") if classic?
        x.gettrustlist do
          x.wmid opt[:wmid]
        end
      }
    }
  end

  def xml_transaction_get(opt)
    Nokogiri::XML::Builder.new{ |x|
      x.send('merchant.request') {
        x.wmid opt[:wmid]
        x.lmi_payee_purse opt[:payee_purse]
        x.lmi_payment_no opt[:orderid]
        x.lmi_payment_no_type opt[:paymenttype]
        x.sign sign("#{opt[:wmid]}#{opt[:payee_purse]}#{opt[:orderid]}")
      }
    }
  end

  def xml_check_user(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('passport.request') {
        x.reqn req
        x.signerwmid @wmid
        x.sign sign("#{req}#{opt[:operation][:type]}#{opt[:userinfo][:wmid]}") if classic?
        x.operation do
          opt[:operation].each do |operation_key, operation_value|
            operation_key = "#{operation_key}_" if operation_key.to_sym == :type
            x.send(operation_key, operation_value)
          end
        end
        x.userinfo do
          opt[:userinfo].each do |userinfo_key, userinfo_value|
            x.send(userinfo_key, userinfo_value)
          end
        end
      }
    }
  end

  def xml_balance(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:wmid]}#{req}") if classic?
        x.getpurses do
          x.wmid opt[:wmid]
        end
      }
    }
  end

  def xml_req_payment(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('merchant.request'){
        x.lmi_payment_no opt[:paymentid]
        x.wmid opt[:wmid]
        x.lmi_payee_purse opt[:purse]
        x.lmi_payment_amount opt[:amount]
        x.lmi_payment_desc opt[:description]
        x.lmi_clientnumber opt[:clientid]
        x.lmi_clientnumber_type opt[:clientidtype]
        x.lmi_sms_type opt[:smstype]
        x.sign sign("#{opt[:wmid]}#{opt[:purse]}#{opt[:paymentid]}#{opt[:clientid]}#{opt[:clientidtype]}")
      }
    }
  end

  def xml_conf_payment(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('merchant.request'){
        x.wmid opt[:wmid]
        x.lmi_payee_purse opt[:purse]
        x.lmi_clientnumber_code opt[:paymentcode]
        x.lmi_wminvoiceid opt[:invoiceid]
        x.sign sign("#{opt[:wmid]}#{opt[:purse]}#{opt[:invoiceid]}#{opt[:paymentcode]}")
      }
    }
  end

  def xml_operation_history(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
        x.send('w3s.request'){
            x.reqn req
            x.wmid opt[:wmid]
            x.sign sign("#{opt[:purse]}#{req}")
            x.getoperations do
                x.purse opt[:purse]
                x.wmtranid opt[:wmtranid] || 0
                x.tranid opt[:tranid] || 0
                x.wminvid opt[:wminvid] || 0
                x.orderid opt[:orderid] || 0
                x.datestart opt[:datestart]
                x.datefinish opt[:datefinish]
            end
        }
    }
  end

  def xml_set_trust(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('merchant.request'){
        x.wmid opt[:wmid]
        x.lmi_payee_purse opt[:purse]
        x.lmi_day_limit opt[:day_limit]
        x.lmi_week_limit opt[:week_limit]
        x.lmi_month_limit opt[:month_limit]
        x.lmi_clientnumber opt[:client_number]
        x.lmi_clientnumber_type opt[:client_number_type]
        x.lmi_sms_type opt[:sms_type]
        x.sign sign("#{opt[:wmid]}#{opt[:purse]}#{opt[:client_number]}#{opt[:client_number_type]}#{opt[:sms_type]}")
        x.lang opt[:lang]
      }
    }
  end

  def xml_confirm_trust(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('merchant.request'){
        x.wmid opt[:wmid]
        x.lmi_purseid opt[:purseid]
        x.lmi_clientnumber_code opt[:clientnumber_code]
        x.sign sign("#{opt[:wmid]}#{opt[:purseid]}#{opt[:clientnumber_code]}")
        x.lang opt[:lang]
      }
    }
  end

  def xml_transaction_moneyback(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{req}#{opt[:tranid]}#{opt[:amount]}") if classic?
        x.trans do
          x.inwmtranid opt[:tranid]
          x.amount opt[:amount]
          x.wmb_denomination 1
        end
      }
    }
  end
end
