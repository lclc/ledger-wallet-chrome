class ledger.tasks.WalletLayoutRecoveryTask extends ledger.tasks.Task

  constructor: -> super 'recovery-global-instance'
  @instance: new @()

  onStart: () ->
    @once 'bip44:done', => @emit 'done'
    @once 'bip44:fatal chronocoin:fatal', => @emit 'fatal_error'

    if ledger.wallet.HDWallet.instance.getAccountsCount() == 0
      @once 'chronocoin:done', => @_restoreBip44Layout()
      @_restoreChronocoinLayout()
    else
      @_restoreBip44Layout()

  onStop: () ->

  _restoreChronocoinLayout: () ->
    wallet = ledger.app.wallet
    wallet.getPublicAddress "0'/0/0", (publicAddress) =>
      wallet.getPublicAddress "0'/1/0", (changeAddress) =>
        ledger.api.TransactionsRestClient.instance.getTransactions [publicAddress.bitcoinAddress.value, changeAddress.bitcoinAddress.value], (transactions, error) =>
          if transactions?.length > 0
            account = ledger.wallet.HDWallet.instance.getOrCreateAccount(0)
            account.importChangeAddressPath("0'/1/0")
            account.importPublicAddressPath("0'/0/0")
            account.save()
          else if error?
            @emit 'chronocoin:fatal'
          else
            ledger.wallet.HDWallet.instance.createAccount()
          @emit 'chronocoin:done'

  _restoreBip44Layout: () ->
    @emit 'bip44:done'