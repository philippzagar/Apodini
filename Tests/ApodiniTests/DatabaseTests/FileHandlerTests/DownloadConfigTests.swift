@testable import ApodiniDatabase
import XCTApodini


final class DownloadConfigTests: FileHandlerTests {
    func testDownloadConfigInfo() throws {
        //Upload file
        let uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try newerXCTCheckHandler(uploader) {
            MockRequest(expectation: .response(status: .created, file.filename)) {
                UnnamedParameter(file)
            }
        }
        
        let directory = app.directory
        let config = DownloadConfiguration(.default)
        let fileInfo = try config.retrieveFileInfo(file.filename, in: directory)
        
        XCTAssertNotNil(fileInfo)
        let info = try XCTUnwrap(fileInfo)
        XCTAssert(info.fileName == file.filename)
        XCTAssert(info.path == directory.publicDirectory + "Misc/Testfile.jpeg")
        let foundData = try Data(contentsOf: URL(fileURLWithPath: info.path))
        XCTAssert(info.readableBytes == foundData.count)
    }
    
    func testDownloadConfigInfos() throws {
        // Upload first file
        var uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try newerXCTCheckHandler(uploader) {
            MockRequest(expectation: .response(status: .created, file.filename)) {
                UnnamedParameter(file)
            }
        }
        
        // Upload second file
        uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/MoreMisc/"))
        let file2 = File(data: data, filename: "Testfile123.jpeg")
        
        try newerXCTCheckHandler(uploader) {
            MockRequest(expectation: .response(status: .created, file2.filename)) {
                UnnamedParameter(file2)
            }
        }
        
        let directory = app.directory
        let config = DownloadConfiguration(.default)
        let fileInfos = try config.retrieveFileInfos(".jpeg", in: directory)
        
        XCTAssertNotNil(fileInfos)
        let infos = try XCTUnwrap(fileInfos)
        XCTAssert(infos[0].fileName == file.filename || infos[0].fileName == file2.filename)
        XCTAssert(infos[1].fileName == file.filename || infos[1].fileName == file2.filename)
    }
}
