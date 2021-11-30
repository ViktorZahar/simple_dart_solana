import * as solWeb3 from '@solana/web3.js';
import BigNumberRaw from './bigraw.js';

class AccountInfo {
    executable: boolean;
    owner: string;
    lamports: number;
    data: string;
    rentEpoch?: number;
    address: string;
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
        var ret: AccountInfo[] = [];
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
            ret.push(accountInfo)
        }
        return ret
    }

    async getStakeActivation(address: string): Promise<solWeb3.StakeActivationData> {
        return await this.conn.getStakeActivation(new solWeb3.PublicKey(address))
    }

    async getMultipleAccountsInfo(addresses: string[]): Promise<any> {
        var ret: AccountInfo[] = [];
        var keys = [];
        for (var i in addresses) {
            const key = new solWeb3.PublicKey(addresses[i])
            keys.push(key)
        }
        const multiInfoRes = await this.conn.getMultipleAccountsInfo(keys, 'confirmed')
        for (var i in multiInfoRes) {
            if (multiInfoRes[i] == null) {
                ret.push(null)
            } else {
                const { data, executable, lamports, owner, rentEpoch } = multiInfoRes[i]
                const accountInfo = new AccountInfo()
                accountInfo.data = Uint8Array.from(data).toString()
                accountInfo.executable = executable
                accountInfo.lamports = lamports
                accountInfo.owner = owner.toString()
                accountInfo.rentEpoch = rentEpoch
                ret.push(accountInfo)
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


const findUserFarmAddress = async (
    authority: string,
    programId: string,
    index: number, // hardcoded to 0 for now
    farm: number,//check FARMS IDs
) => {
    let seeds = [
        new solWeb3.PublicKey(authority).toBuffer(),
        new BigNumberRaw(index).toArrayLike(Buffer, "le", 8),
        new BigNumberRaw(farm).toArrayLike(Buffer, "le", 8),
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
        new BigNumberRaw(obligationIndex).toArrayLike(Buffer, "le", 8),
    ];

    return solWeb3.PublicKey.findProgramAddress(seeds, new solWeb3.PublicKey(programId));
};

window['SolanaWrapper'] = SolanaWrapper
window['publicKeyFromArray'] = publicKeyFromArray


const toArrayLike = function toArrayLike ( val:number, endian, length) {

    var byteLength = this.byteLength();
    var reqLength = length || Math.max(1, byteLength);

    var res = new Buffer(reqLength);
    var position = 0;
    var carry = 0;

    for (var i = 0, shift = 0; i < this.length; i++) {
      var word = (this.words[i] << shift) | carry;

      res[position++] = word & 0xff;
      if (position < res.length) {
        res[position++] = (word >> 8) & 0xff;
      }
      if (position < res.length) {
        res[position++] = (word >> 16) & 0xff;
      }

      if (shift === 6) {
        if (position < res.length) {
          res[position++] = (word >> 24) & 0xff;
        }
        carry = 0;
        shift = 0;
      } else {
        carry = word >>> 24;
        shift += 2;
      }
    }

    if (position < res.length) {
      res[position++] = carry;

      while (position < res.length) {
        res[position++] = 0;
      }
    }
    return res;
  };

