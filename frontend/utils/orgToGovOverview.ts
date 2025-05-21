
import { Law, Powers } from "@/context/types";

export const orgToGovernanceTracks = (powers: Powers): {tracks: Law[][] | undefined , orphans: Law[] | undefined}  => {

  const childLawIds = powers.activeLaws?.map(law => Number(law.conditions?.needCompleted))
      .concat(powers.activeLaws?.map(law => Number(law.conditions?.needNotCompleted)))
      .concat(powers.activeLaws?.map(law => Number(law.conditions?.readStateFrom)))

  // console.log("@orgToGovernanceTracks, childLawIds: ", childLawIds)

  const childLaws = powers.activeLaws?.filter(law => childLawIds?.includes(Number(law.index)))
  // console.log("@orgToGovernanceTracks, childLaws: ", childLaws)
  const parentLaws = powers.activeLaws?.filter(law => law.conditions?.needCompleted != 0n || law.conditions?.needNotCompleted != 0n || law.conditions?.readStateFrom != 0n ) 
  // console.log("@orgToGovernanceTracks, parentLaws: ", parentLaws)
  
  const start: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == false)
  // console.log("@orgToGovernanceTracks, start: ", start)
  const middle: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == true)
  // console.log("@orgToGovernanceTracks, middle: ", middle)
  const end: Law[] | undefined = parentLaws?.filter(law => childLaws?.includes(law) == false)
  // console.log("@orgToGovernanceTracks, end: ", end)
  const orphans = powers.activeLaws?.filter(law => childLaws?.includes(law) == false && parentLaws?.includes(law) == false)
  // console.log("@orgToGovernanceTracks, orphans: ", orphans)

  const tracks1 = end?.map(law => {
    const dependencies = [Number(law.conditions?.needCompleted), Number(law.conditions?.needNotCompleted), Number(law.conditions?.readStateFrom)]
    const dependentLaws = middle?.filter(law1 => dependencies?.includes(Number(law1.index))) 

    return dependentLaws ?  [law].concat(dependentLaws) : [law]
  })

  // console.log("@orgToGovernanceTracks, tracks1: ", tracks1)

  const tracks2 = tracks1?.map(lawList => {
    const dependencies = lawList.map(law => Number(law.conditions?.needCompleted)).concat(lawList.map(law => Number(law.conditions?.needNotCompleted))).concat(lawList.map(law => Number(law.conditions?.readStateFrom)))
    const dependentLaws = start?.filter(law1 => dependencies?.includes(Number(law1.index))) 
    
    return dependentLaws ?  lawList.concat(dependentLaws).reverse() : lawList.reverse()
  })

  // console.log("@orgToGovernanceTracks, tracks2: ", tracks2)

  const result = {
    tracks: tracks2,
    orphans: orphans 
  }

  // console.log("@orgToGovernanceTracks, result: ", result)

  return result

};