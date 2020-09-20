//
//   DCMPDFImportFilter
//  
//

#import "DCMPDFImportFilter.h"
#import <OsiriX/DCM.h>

#import "OsiriXAPI/browserController.h"
#import "OsiriXAPI/DicomFile.h"
#import "OsiriXAPI/DicomDatabase.h"
#import "OsiriXAPI/DicomStudy+Report.h"

@implementation DCMPDFImportFilter

- (long) filterImage:(NSString*) menuName
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *currentSelection = [[BrowserController currentBrowser] databaseSelection];
	if ([currentSelection count] > 0)
	{
		id selection = [currentSelection objectAtIndex:0];
		NSString *source;
		
		if ([[[selection entity] name] isEqualToString:@"Study"]) 
			source = [[[[[selection valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject] valueForKey:@"completePath"];
		else
			source = [[[selection valueForKey:@"images"] anyObject] valueForKey:@"completePath"];
		
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowsMultipleSelection:YES];
		[openPanel setTitle:NSLocalizedString(@"Import", nil)];
		[openPanel setMessage:NSLocalizedString(@"Select PDF or folder of PDFs to convert to DICOM", nil)];
		
		if([openPanel runModalForTypes:[NSArray arrayWithObject:@"pdf"]] == NSOKButton)
		{
			NSEnumerator *enumerator = [[openPanel filenames] objectEnumerator];
			NSString *fpath;
			BOOL isDir;
			while(fpath = [enumerator nextObject])
			{
				[[NSFileManager defaultManager] fileExistsAtPath:fpath isDirectory:&isDir];
				
				//loop through directory if true
				if (isDir)
				{
					NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:fpath];
					NSString *path;
					while (path = [dirEnumerator nextObject])
						if  ([[NSImage imageFileTypes] containsObject:[path pathExtension]])
                        {
                            NSString *newDCM = [[[BrowserController currentBrowser] database] uniquePathForNewDataFileWithExtension: @"dcm"];
                            
                            [DicomStudy transformPdfAtPath: [fpath stringByAppendingPathComponent:path] toDicomAtPath: newDCM usingSourceDicomAtPath: source];
                            
                            [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: newDCM]
                               postNotifications: YES
                                       dicomOnly: YES
                             rereadExistingItems: YES
                               generatedByOsiriX: YES];
                        }
				}
				else
                {
                    NSString *newDCM = [[[BrowserController currentBrowser] database] uniquePathForNewDataFileWithExtension: @"dcm"];
                    
                    [DicomStudy transformPdfAtPath: fpath toDicomAtPath: newDCM usingSourceDicomAtPath: source];
                    
                    [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: newDCM]
                                                             postNotifications: YES
                                                                     dicomOnly: YES
                                                           rereadExistingItems: YES
                                                             generatedByOsiriX: YES];
                }
			}
		}
	}
    else NSRunAlertPanel( @"PDF to DICOM", @"First, select a study in the database where to put the PDF.", @"OK", nil, nil);
	
	[pool release];
	
	return 0;
}

//- (void)convertImageToDICOM:(NSString *)path source:(NSString *) source
//{
//	@autoreleasepool
//    {
//        NSMutableData *pdf = nil;
//        if ([[path pathExtension] isEqualToString:@"pdf"])
//            pdf = [NSMutableData dataWithContentsOfFile:path];	
//        
//        //if we have an image  get the info we need from the imageRep.
//        if( pdf)
//        {
//            id patientName = nil, patientID = nil, studyDescription = nil, studyUID = nil, studyID = nil, studyDate = nil;
//            id studyTime = nil, seriesDate = nil, seriesTime = nil, acquisitionDate = nil, acquisitionTime = nil;
//            id contentDate = nil, contentTime = nil, charSet = nil, patientSex = nil, accessionNumber = nil, patientsBirthDate = nil, referringPhysiciansName = nil, institutionName = nil;
//            
//            if ([DicomFile isDICOMFile: source])
//            {
//                DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: source decodingPixelData:NO];
//                
//                patientName = [dcmObject attributeValueWithName:@"PatientsName"];
//                patientID = [dcmObject attributeValueWithName:@"PatientID"];
//                studyDescription = [dcmObject attributeValueWithName:@"StudyDescription"];
//                studyUID = [dcmObject attributeValueWithName:@"StudyInstanceUID"];
//                studyID = [dcmObject attributeValueWithName:@"StudyID"];
//                studyDate = [dcmObject attributeValueWithName:@"StudyDate"];
//                studyTime = [dcmObject attributeValueWithName:@"StudyTime"];
//                seriesDate = [dcmObject attributeValueWithName:@"SeriesDate"];
//                seriesTime = [dcmObject attributeValueWithName:@"SeriesTime"];
//                acquisitionDate = [dcmObject attributeValueWithName:@"AcquisitionDate"];
//                acquisitionTime = [dcmObject attributeValueWithName:@"AcquisitionTime"];
//                contentDate = [dcmObject attributeValueWithName:@"ContentDate"];
//                contentTime = [dcmObject attributeValueWithName:@"ContentTime"];
//                charSet = [dcmObject attributeValueWithName:@"SpecificCharacterSet"];
//                patientSex = [dcmObject attributeValueWithName:@"PatientsSex"];
//                accessionNumber = [dcmObject attributeValueWithName:@"AccessionNumber"];
//                patientsBirthDate = [dcmObject attributeValueWithName:@"PatientsBirthDate"];
//                institutionName = [dcmObject attributeValueWithName:@"InstitutionName"];
//                
//                referringPhysiciansName = [dcmObject attributeValueWithName:@"ReferringPhysiciansName"];
//            }
//            
//            // pad data
//            if ([pdf length] % 2 != 0)
//                [pdf increaseLengthBy:1];
//            // create DICOM OBJECT
//            DCMObject *dcmObject = [DCMObject encapsulatedPDF:pdf];
//            
//            if( charSet)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: charSet] forName:@"SpecificCharacterSet"];
//            
//            if( studyUID)
//                [dcmObject setAttributeValues:[NSArray arrayWithObject: studyUID] forName:@"StudyInstanceUID"];
//            [dcmObject setAttributeValues:[NSArray arrayWithObject: [[path lastPathComponent] stringByDeletingPathExtension]] forName:@"SeriesDescription"];
//            
//            if (patientName)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: patientName] forName:@"PatientsName"];
//            else
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: @""] forName:@"PatientsName"];
//                
//            if (patientID)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: patientID] forName:@"PatientID"];
//            else
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: @"0"] forName:@"PatientID"];
//            
//            if (patientsBirthDate)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: [DCMCalendarDate dicomDateWithDate: patientsBirthDate]] forName:@"PatientsBirthDate"];
//            
//            if (accessionNumber)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: accessionNumber] forName:@"AccessionNumber"];
//            
//            if( referringPhysiciansName)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: referringPhysiciansName] forName:@"ReferringPhysiciansName"];
//            
//            if( institutionName)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: institutionName] forName:@"InstitutionName"];
//            
//            if( studyDescription)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: studyDescription] forName:@"StudyDescription"];
//            
//            if (patientSex)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: patientSex] forName:@"PatientsSex"];
//            else
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: @""] forName:@"PatientsSex"];
//            
//            [dcmObject setAttributeValues:[NSMutableArray arrayWithObject: [[path lastPathComponent] stringByDeletingPathExtension]] forName:@"DocumentTitle"];
//                
//            [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", imageNumber]] forName:@"InstanceNumber"];
//            
//            if ( studyID)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", (int) studyID]] forName:@"StudyID"];
//            else
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", 0001]] forName:@"StudyID"];
//                
//            if (studyDate)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate: studyDate]] forName:@"StudyDate"];
//            else
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate:[NSDate date]]] forName:@"StudyDate"];
//                
//            if (studyTime)	
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:studyTime]] forName:@"StudyTime"];
//            else
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]] forName:@"StudyTime"];
//
//            if (seriesDate)
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate: seriesDate]] forName:@"SeriesDate"];
//            else
//            
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]] forName:@"SeriesDate"];
//            
//            if (seriesTime) 
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:seriesTime]] forName:@"SeriesTime"];
//            else			
//                [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]] forName:@"SeriesTime"];
//            
//            [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"9997"] forName:@"SeriesNumber"];
//            
//            NSString *filePath = [BrowserController.currentBrowser.database uniquePathForNewDataFileWithExtension: @"dcm"];
//            
//            if( [dcmObject writeToFile:filePath withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES])
//                NSLog(@"Wrote PDF to %@", filePath);
//            
//            if( [[NSFileManager defaultManager] fileExistsAtPath: filePath])
//                [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: filePath]
//                                                         postNotifications: YES
//                                                                 dicomOnly: YES
//                                                       rereadExistingItems: YES
//                                                         generatedByOsiriX: YES];
//            
//            
//        }
//    }
//}
@end
