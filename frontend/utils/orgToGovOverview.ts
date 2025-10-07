
import { Law, Powers } from "@/context/types";

export const orgToGovernanceTracks = (powers: Powers): {tracks: Law[][] | undefined , orphans: Law[] | undefined}  => {

  const childLawIds = powers.AdoptedLaws?.map(law => Number(law.conditions?.needFulfilled))
      .concat(powers.AdoptedLaws?.map(law => Number(law.conditions?.needNotFulfilled)))
      .concat(powers.AdoptedLaws?.map(law => Number(law.conditions?.readStateFrom)))

  // console.log("@orgToGovernanceTracks, childLawIds: ", childLawIds)

  const childLaws = powers.AdoptedLaws?.filter(law => childLawIds?.includes(Number(law.index)))
  // console.log("@orgToGovernanceTracks, childLaws: ", childLaws)
  const parentLaws = powers.AdoptedLaws?.filter(law => law.conditions?.needFulfilled != 0n || law.conditions?.needNotFulfilled != 0n || law.conditions?.readStateFrom != 0n ) 
  // console.log("@orgToGovernanceTracks, parentLaws: ", parentLaws)
  
  const start: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == false)
  // console.log("@orgToGovernanceTracks, start: ", start)
  const middle: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == true)
  // console.log("@orgToGovernanceTracks, middle: ", middle)
  const end: Law[] | undefined = parentLaws?.filter(law => childLaws?.includes(law) == false)
  // console.log("@orgToGovernanceTracks, end: ", end)
  const orphans = powers.AdoptedLaws?.filter(law => childLaws?.includes(law) == false && parentLaws?.includes(law) == false)
  // console.log("@orgToGovernanceTracks, orphans: ", orphans)

  const tracks1 = end?.map(law => {
    const dependencies = [Number(law.conditions?.needFulfilled), Number(law.conditions?.needNotFulfilled), Number(law.conditions?.readStateFrom)]
    const dependentLaws = middle?.filter(law1 => dependencies?.includes(Number(law1.index))) 

    return dependentLaws ?  [law].concat(dependentLaws) : [law]
  })

  // console.log("@orgToGovernanceTracks, tracks1: ", tracks1)

  const tracks2 = tracks1?.map(lawList => {
    const dependencies = lawList.map(law => Number(law.conditions?.needFulfilled)).concat(lawList.map(law => Number(law.conditions?.needNotFulfilled))).concat(lawList.map(law => Number(law.conditions?.readStateFrom)))
    const dependentLaws = start?.filter(law1 => dependencies?.includes(Number(law1.index))) 
    
    return dependentLaws ?  lawList.concat(dependentLaws).reverse() : lawList.reverse()
  })

  // console.log("@orgToGovernanceTracks, tracks2: ", tracks2)

  const result = {
    tracks: tracks2,
    orphans 
  }

  // console.log("@orgToGovernanceTracks, result: ", result)

  return result

};