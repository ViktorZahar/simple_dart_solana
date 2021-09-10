import * as solWeb3 from '@solana/web3.js';

export class SolanaWrapper {
    conn: solWeb3.Connection
    constructor(url: string) {
        this.conn = new solWeb3.Connection(url)
    }

    async getTokenAccountBalance(address: string): Promise<any> {
        return this.conn.getTokenAccountBalance(new solWeb3.PublicKey(address))
    }

    async getBalance(address: string): Promise<any> {
        const bal = await this.conn.getBalance(new solWeb3.PublicKey(address))
        return bal / (10 ** 9)
    }

    async getAllTokenAccountsByOwner(address: string): Promise<Array<String>> {
        const res = await this.conn.getParsedTokenAccountsByOwner(new solWeb3.PublicKey(address),
            { programId: new solWeb3.PublicKey('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA') })
        const resMapped = res['value'].map((e) => {
            return new solWeb3.PublicKey(e.account.data.parsed.info.mint).toString() + '|' + e.account.data.parsed.info.tokenAmount.uiAmountString
        }
        )
        return resMapped
    }

    async getAccountOwner(address: string): Promise<string> {
        const resp = await this.conn.getParsedAccountInfo(new solWeb3.PublicKey(address))
        const data = <solWeb3.ParsedAccountData>resp.value.data
        if ('parsed' in data) {
            return new solWeb3.PublicKey(data.parsed.info.owner).toString()
        } else {
            return ''
        }
    }

    async getStaked(address: string): Promise<any> {
        var ret = {};
        const stakeAccounts = await this.conn.getParsedProgramAccounts(
            new solWeb3.PublicKey('Stake11111111111111111111111111111111111111'),
            {
                filters: [
                    { memcmp: { offset: 12, bytes: address } }]
            })
        for (var i = 0; i < stakeAccounts.length; i++) {
            const stakeAccount = stakeAccounts[i]
            const resp = await this.conn.getStakeActivation(stakeAccount.pubkey)
            ret[stakeAccount.pubkey.toString()] = resp.active
        }

        return ret

    }
}

window['SolanaWrapper'] = SolanaWrapper