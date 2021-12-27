import * as solWeb3 from '@solana/web3.js';

class AccountInfo {
    executable: boolean = false;
    owner: string = '';
    lamports: number = 0;
    data: string = '';
    rentEpoch?: number = 0;
    address: string = '';
}

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
        if (resp.value == null) {
            return ''
        }
        const data = <solWeb3.ParsedAccountData>resp.value.data
        if ('parsed' in data) {
            return new solWeb3.PublicKey(data.parsed.info.owner).toString()
        } else {
            return ''
        }
    }

    async getProgramAccounts(programAddress: string, filterAddress = '', offset = 0): Promise<any> {
        var ret: string[] = [];
        const filters = []
        if (filterAddress != '') {
            filters.push({ memcmp: { offset: offset, bytes: filterAddress } })
        }
        const res = await this.conn.getProgramAccounts(new solWeb3.PublicKey(programAddress),
            {
                filters: filters
            });
        for (var i in res) {
            const { data, executable, lamports, owner, rentEpoch } = res[i].account
            const accountInfo = new AccountInfo()
            accountInfo.data = Uint8Array.from(data).toString()
            accountInfo.executable = executable
            accountInfo.lamports = lamports
            accountInfo.owner = owner.toString()
            accountInfo.rentEpoch = rentEpoch
            accountInfo.address = res[i].pubkey.toString()
            ret.push(JSON.stringify(accountInfo))
        }
        return ret
    }

    async getStakeActivation(address: string): Promise<string> {
        return JSON.stringify(await this.conn.getStakeActivation(new solWeb3.PublicKey(address)))
    }

    async getMultipleAccountsInfo(addresses: string[]): Promise<any> {
        var ret: string[] = [];
        var keys = [];
        for (var i in addresses) {
            const key = new solWeb3.PublicKey(addresses[i])
            keys.push(key)
        }
        const multiInfoRes = await this.conn.getMultipleAccountsInfo(keys, 'finalized')
        for (var i in multiInfoRes) {
            if (multiInfoRes[i] == null) {
                ret.push('-')
            } else {
                const { data, executable, lamports, owner, rentEpoch } = multiInfoRes[i]
                const accountInfo = new AccountInfo()
                accountInfo.data = Uint8Array.from(data).toString()
                accountInfo.executable = executable
                accountInfo.lamports = lamports
                accountInfo.owner = owner.toString()
                accountInfo.rentEpoch = rentEpoch
                ret.push(JSON.stringify(accountInfo))
            }
        }
        return ret
    }

    async findFarmsolObligationAddress(address: string, programAddress: string, farmIndex: number, obligationIndex: number, userAddressIndex: number): Promise<any> {
        let key = await findUserFarmAddress(address, programAddress, userAddressIndex, farmIndex);

        let [userObligationAcct1] = await findUserFarmObligationAddress(address, key[0], programAddress, obligationIndex);
        return userObligationAcct1.toString()
    }

}

function publicKeyFromArray(arr: Array<number>): string {
    return new solWeb3.PublicKey(arr).toString()
}


async function findUserFarmAddress(
    authority: string,
    programId: string,
    index: number, // hardcoded to 0 for now
    farm: number,//check FARMS IDs
): Promise<any> {
    let seeds = [
        new solWeb3.PublicKey(authority).toBuffer(),
        convertToArrayLike(index),
        convertToArrayLike(farm)
    ];

    let k = await solWeb3.PublicKey.findProgramAddress(seeds, new solWeb3.PublicKey(programId));
    return k;
}

/**
 *
 * @param {Authority address} authority base58
 * @param {Address found with findProgramAddress } userFarmAddr base58
 * @param {Leverage programid } programId
 * @param {index obligation on USER_FARM} obligationIndex
 * @returns
 */
const findUserFarmObligationAddress = async (
    authority: string,
    userFarmAddr,
    programId: string,
    obligationIndex: number
) => {
    let seeds = [
        new solWeb3.PublicKey(authority).toBuffer(),
        userFarmAddr.toBuffer(),
        convertToArrayLike(obligationIndex)
    ];

    return solWeb3.PublicKey.findProgramAddress(seeds, new solWeb3.PublicKey(programId));
};

window['SolanaWrapper'] = SolanaWrapper
window['publicKeyFromArray'] = publicKeyFromArray

const convertToArrayLike = num => {
    let b = new ArrayBuffer(8);
    new DataView(b).setUint32(0, num, true);
    return new Uint8Array(b);
}