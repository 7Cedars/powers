
import { Law, Powers } from "@/context/types";

export const orgToGovernanceTracks = (powers: Powers): {tracks: Law[][] | undefined , orphans: Law[] | undefined}  => {  

  // console.log("@orgToGovernanceTracks: ", {organisation})

  const childLawAddresses = powers.activeLaws?.map(law => law.conditions.needCompleted
      ).concat(powers.activeLaws?.map(law => law.conditions.needNotCompleted)
      ).concat(powers.activeLaws?.map(law => law.conditions.readStateFrom)
    )
  const childLaws = powers.activeLaws?.filter(law => childLawAddresses?.includes(law.index))
  const parentLaws = powers.activeLaws?.filter(law => law.conditions.needCompleted != 0n || law.conditions.needNotCompleted != 0n || law.conditions.readStateFrom != 0n ) 

  const start: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == false)
  const middle: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == true)
  const end: Law[] | undefined = parentLaws?.filter(law => childLaws?.includes(law) == false)
  const orphans = powers.activeLaws?.filter(law => childLaws?.includes(law) == false && parentLaws?.includes(law) == false)

  // console.log("@orgToGovernanceTracks: ", {start, middle, end, orphans})

  const tracks1 = end?.map(law => {
    const dependencies = [law.conditions.needCompleted, law.conditions.needNotCompleted, law.conditions.readStateFrom]
    const dependentLaws = middle?.filter(law1 => dependencies?.includes(law1.index)) 

    return dependentLaws ?  [law].concat(dependentLaws) : [law]
  })

  const tracks2 = tracks1?.map(lawList => {
    const dependencies = lawList.map(law => law.conditions.needCompleted).concat(lawList.map(law => law.conditions.needNotCompleted)).concat(lawList.map(law => law.conditions.readStateFrom))
    const dependentLaws = start?.filter(law1 => dependencies?.includes(law1.index)) 

    return dependentLaws ?  lawList.concat(dependentLaws).reverse() : lawList.reverse()
  })

  const result = {
    tracks: tracks2,
    orphans: orphans 
  }

  // console.log("@orgToGovernanceTracks: ", {result})

  return result

};