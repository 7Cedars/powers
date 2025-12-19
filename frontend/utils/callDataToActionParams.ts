import { Action, Powers } from "@/context/types";
import { Mandate } from "@/context/types";
import { DataType } from "@/context/types";
import { decodeAbiParameters } from "viem";
import { parseAbiParameters } from "viem";
import { parseParamValues } from "@/utils/parsers";


export const callDataToActionParams = (action: Action, powers: Powers | undefined) => {
    const mandate = powers?.mandates?.find(mandate => mandate.index == action.mandateId) as Mandate
    const dataTypes = mandate.params?.map((param: { varName: string; dataType: DataType }) => param.dataType) || []
    if (dataTypes.length > 0) {
      const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), action.callData as `0x${string}`);
      return parseParamValues(values) 
    } else {
      return []
    }
  }
