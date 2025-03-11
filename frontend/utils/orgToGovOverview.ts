
import { Law, Organisation } from "@/context/types";

export const orgToGovernanceTracks = (organisation: Organisation): {tracks: Law[][] | undefined , orphans: Law[] | undefined}  => {  

  // console.log("@orgToGovernanceTracks: ", {organisation})

  const childLawAddresses = organisation.activeLaws?.map(law => law.config.needCompleted
      ).concat(organisation.activeLaws?.map(law => law.config.needNotCompleted)
      ).concat(organisation.activeLaws?.map(law => law.config.readStateFrom)
    )
  const childLaws = organisation.activeLaws?.filter(law => childLawAddresses?.includes(law.law))
  const parentLaws = organisation.activeLaws?.filter(law => law.config.needCompleted != `0x${'0'.repeat(40)}` || law.config.needNotCompleted != `0x${'0'.repeat(40)}` || law.config.readStateFrom != `0x${'0'.repeat(40)}` ) 

  const start: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == false)
  const middle: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == true)
  const end: Law[] | undefined = parentLaws?.filter(law => childLaws?.includes(law) == false)
  const orphans = organisation.activeLaws?.filter(law => childLaws?.includes(law) == false && parentLaws?.includes(law) == false)

  // console.log("@orgToGovernanceTracks: ", {start, middle, end, orphans})

  const tracks1 = end?.map(law => {
    const dependencies = [law.config.needCompleted, law.config.needNotCompleted, law.config.readStateFrom]
    const dependentLaws = middle?.filter(law1 => dependencies?.includes(law1.law)) 

    return dependentLaws ?  [law].concat(dependentLaws) : [law]
  })

  const tracks2 = tracks1?.map(lawList => {
    const dependencies = lawList.map(law => law.config.needCompleted).concat(lawList.map(law => law.config.needNotCompleted)).concat(lawList.map(law => law.config.readStateFrom))
    const dependentLaws = start?.filter(law1 => dependencies?.includes(law1.law)) 

    return dependentLaws ?  lawList.concat(dependentLaws).reverse() : lawList.reverse()
  })

  const result = {
    tracks: tracks2,
    orphans: orphans 
  }

  // console.log("@orgToGovernanceTracks: ", {result})

  return result

};