
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Import/Export
## version: 2010-06-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Import/Export Service</fullname> AWS Import/Export accelerates transferring large amounts of data between the AWS cloud and portable storage devices that you mail to us. AWS Import/Export transfers data directly onto and off of your storage devices using Amazon's high-speed internal network and bypassing the Internet. For large data sets, AWS Import/Export is often faster than Internet transfer and more cost effective than upgrading your connectivity.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/importexport/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "importexport"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostCancelJob_773188 = ref object of OpenApiRestCall_772581
proc url_PostCancelJob_773190(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCancelJob_773189(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773191 = query.getOrDefault("SignatureMethod")
  valid_773191 = validateParameter(valid_773191, JString, required = true,
                                 default = nil)
  if valid_773191 != nil:
    section.add "SignatureMethod", valid_773191
  var valid_773192 = query.getOrDefault("Signature")
  valid_773192 = validateParameter(valid_773192, JString, required = true,
                                 default = nil)
  if valid_773192 != nil:
    section.add "Signature", valid_773192
  var valid_773193 = query.getOrDefault("Action")
  valid_773193 = validateParameter(valid_773193, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_773193 != nil:
    section.add "Action", valid_773193
  var valid_773194 = query.getOrDefault("Timestamp")
  valid_773194 = validateParameter(valid_773194, JString, required = true,
                                 default = nil)
  if valid_773194 != nil:
    section.add "Timestamp", valid_773194
  var valid_773195 = query.getOrDefault("Operation")
  valid_773195 = validateParameter(valid_773195, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_773195 != nil:
    section.add "Operation", valid_773195
  var valid_773196 = query.getOrDefault("SignatureVersion")
  valid_773196 = validateParameter(valid_773196, JString, required = true,
                                 default = nil)
  if valid_773196 != nil:
    section.add "SignatureVersion", valid_773196
  var valid_773197 = query.getOrDefault("AWSAccessKeyId")
  valid_773197 = validateParameter(valid_773197, JString, required = true,
                                 default = nil)
  if valid_773197 != nil:
    section.add "AWSAccessKeyId", valid_773197
  var valid_773198 = query.getOrDefault("Version")
  valid_773198 = validateParameter(valid_773198, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773198 != nil:
    section.add "Version", valid_773198
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_773199 = formData.getOrDefault("JobId")
  valid_773199 = validateParameter(valid_773199, JString, required = true,
                                 default = nil)
  if valid_773199 != nil:
    section.add "JobId", valid_773199
  var valid_773200 = formData.getOrDefault("APIVersion")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "APIVersion", valid_773200
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773201: Call_PostCancelJob_773188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_773201.validator(path, query, header, formData, body)
  let scheme = call_773201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773201.url(scheme.get, call_773201.host, call_773201.base,
                         call_773201.route, valid.getOrDefault("path"))
  result = hook(call_773201, url, valid)

proc call*(call_773202: Call_PostCancelJob_773188; SignatureMethod: string;
          Signature: string; Timestamp: string; JobId: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "CancelJob"; Operation: string = "CancelJob";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_773203 = newJObject()
  var formData_773204 = newJObject()
  add(query_773203, "SignatureMethod", newJString(SignatureMethod))
  add(query_773203, "Signature", newJString(Signature))
  add(query_773203, "Action", newJString(Action))
  add(query_773203, "Timestamp", newJString(Timestamp))
  add(formData_773204, "JobId", newJString(JobId))
  add(query_773203, "Operation", newJString(Operation))
  add(query_773203, "SignatureVersion", newJString(SignatureVersion))
  add(query_773203, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773203, "Version", newJString(Version))
  add(formData_773204, "APIVersion", newJString(APIVersion))
  result = call_773202.call(nil, query_773203, nil, formData_773204, nil)

var postCancelJob* = Call_PostCancelJob_773188(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_773189, base: "/", url: url_PostCancelJob_773190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_772917 = ref object of OpenApiRestCall_772581
proc url_GetCancelJob_772919(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCancelJob_772918(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773031 = query.getOrDefault("SignatureMethod")
  valid_773031 = validateParameter(valid_773031, JString, required = true,
                                 default = nil)
  if valid_773031 != nil:
    section.add "SignatureMethod", valid_773031
  var valid_773032 = query.getOrDefault("JobId")
  valid_773032 = validateParameter(valid_773032, JString, required = true,
                                 default = nil)
  if valid_773032 != nil:
    section.add "JobId", valid_773032
  var valid_773033 = query.getOrDefault("APIVersion")
  valid_773033 = validateParameter(valid_773033, JString, required = false,
                                 default = nil)
  if valid_773033 != nil:
    section.add "APIVersion", valid_773033
  var valid_773034 = query.getOrDefault("Signature")
  valid_773034 = validateParameter(valid_773034, JString, required = true,
                                 default = nil)
  if valid_773034 != nil:
    section.add "Signature", valid_773034
  var valid_773048 = query.getOrDefault("Action")
  valid_773048 = validateParameter(valid_773048, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_773048 != nil:
    section.add "Action", valid_773048
  var valid_773049 = query.getOrDefault("Timestamp")
  valid_773049 = validateParameter(valid_773049, JString, required = true,
                                 default = nil)
  if valid_773049 != nil:
    section.add "Timestamp", valid_773049
  var valid_773050 = query.getOrDefault("Operation")
  valid_773050 = validateParameter(valid_773050, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_773050 != nil:
    section.add "Operation", valid_773050
  var valid_773051 = query.getOrDefault("SignatureVersion")
  valid_773051 = validateParameter(valid_773051, JString, required = true,
                                 default = nil)
  if valid_773051 != nil:
    section.add "SignatureVersion", valid_773051
  var valid_773052 = query.getOrDefault("AWSAccessKeyId")
  valid_773052 = validateParameter(valid_773052, JString, required = true,
                                 default = nil)
  if valid_773052 != nil:
    section.add "AWSAccessKeyId", valid_773052
  var valid_773053 = query.getOrDefault("Version")
  valid_773053 = validateParameter(valid_773053, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773053 != nil:
    section.add "Version", valid_773053
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773076: Call_GetCancelJob_772917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_773076.validator(path, query, header, formData, body)
  let scheme = call_773076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773076.url(scheme.get, call_773076.host, call_773076.base,
                         call_773076.route, valid.getOrDefault("path"))
  result = hook(call_773076, url, valid)

proc call*(call_773147: Call_GetCancelJob_772917; SignatureMethod: string;
          JobId: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; APIVersion: string = "";
          Action: string = "CancelJob"; Operation: string = "CancelJob";
          Version: string = "2010-06-01"): Recallable =
  ## getCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   SignatureMethod: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_773148 = newJObject()
  add(query_773148, "SignatureMethod", newJString(SignatureMethod))
  add(query_773148, "JobId", newJString(JobId))
  add(query_773148, "APIVersion", newJString(APIVersion))
  add(query_773148, "Signature", newJString(Signature))
  add(query_773148, "Action", newJString(Action))
  add(query_773148, "Timestamp", newJString(Timestamp))
  add(query_773148, "Operation", newJString(Operation))
  add(query_773148, "SignatureVersion", newJString(SignatureVersion))
  add(query_773148, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773148, "Version", newJString(Version))
  result = call_773147.call(nil, query_773148, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_772917(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_772918, base: "/", url: url_GetCancelJob_772919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_773224 = ref object of OpenApiRestCall_772581
proc url_PostCreateJob_773226(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateJob_773225(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773227 = query.getOrDefault("SignatureMethod")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = nil)
  if valid_773227 != nil:
    section.add "SignatureMethod", valid_773227
  var valid_773228 = query.getOrDefault("Signature")
  valid_773228 = validateParameter(valid_773228, JString, required = true,
                                 default = nil)
  if valid_773228 != nil:
    section.add "Signature", valid_773228
  var valid_773229 = query.getOrDefault("Action")
  valid_773229 = validateParameter(valid_773229, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_773229 != nil:
    section.add "Action", valid_773229
  var valid_773230 = query.getOrDefault("Timestamp")
  valid_773230 = validateParameter(valid_773230, JString, required = true,
                                 default = nil)
  if valid_773230 != nil:
    section.add "Timestamp", valid_773230
  var valid_773231 = query.getOrDefault("Operation")
  valid_773231 = validateParameter(valid_773231, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_773231 != nil:
    section.add "Operation", valid_773231
  var valid_773232 = query.getOrDefault("SignatureVersion")
  valid_773232 = validateParameter(valid_773232, JString, required = true,
                                 default = nil)
  if valid_773232 != nil:
    section.add "SignatureVersion", valid_773232
  var valid_773233 = query.getOrDefault("AWSAccessKeyId")
  valid_773233 = validateParameter(valid_773233, JString, required = true,
                                 default = nil)
  if valid_773233 != nil:
    section.add "AWSAccessKeyId", valid_773233
  var valid_773234 = query.getOrDefault("Version")
  valid_773234 = validateParameter(valid_773234, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773234 != nil:
    section.add "Version", valid_773234
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   ManifestAddendum: JString
  ##                   : For internal use only.
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  var valid_773235 = formData.getOrDefault("ManifestAddendum")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "ManifestAddendum", valid_773235
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_773236 = formData.getOrDefault("Manifest")
  valid_773236 = validateParameter(valid_773236, JString, required = true,
                                 default = nil)
  if valid_773236 != nil:
    section.add "Manifest", valid_773236
  var valid_773237 = formData.getOrDefault("JobType")
  valid_773237 = validateParameter(valid_773237, JString, required = true,
                                 default = newJString("Import"))
  if valid_773237 != nil:
    section.add "JobType", valid_773237
  var valid_773238 = formData.getOrDefault("ValidateOnly")
  valid_773238 = validateParameter(valid_773238, JBool, required = true, default = nil)
  if valid_773238 != nil:
    section.add "ValidateOnly", valid_773238
  var valid_773239 = formData.getOrDefault("APIVersion")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "APIVersion", valid_773239
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773240: Call_PostCreateJob_773224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_773240.validator(path, query, header, formData, body)
  let scheme = call_773240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773240.url(scheme.get, call_773240.host, call_773240.base,
                         call_773240.route, valid.getOrDefault("path"))
  result = hook(call_773240, url, valid)

proc call*(call_773241: Call_PostCreateJob_773224; SignatureMethod: string;
          Signature: string; Manifest: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; ValidateOnly: bool;
          ManifestAddendum: string = ""; JobType: string = "Import";
          Action: string = "CreateJob"; Operation: string = "CreateJob";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   SignatureMethod: string (required)
  ##   ManifestAddendum: string
  ##                   : For internal use only.
  ##   Signature: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_773242 = newJObject()
  var formData_773243 = newJObject()
  add(query_773242, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773243, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_773242, "Signature", newJString(Signature))
  add(formData_773243, "Manifest", newJString(Manifest))
  add(formData_773243, "JobType", newJString(JobType))
  add(query_773242, "Action", newJString(Action))
  add(query_773242, "Timestamp", newJString(Timestamp))
  add(query_773242, "Operation", newJString(Operation))
  add(query_773242, "SignatureVersion", newJString(SignatureVersion))
  add(query_773242, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773242, "Version", newJString(Version))
  add(formData_773243, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_773243, "APIVersion", newJString(APIVersion))
  result = call_773241.call(nil, query_773242, nil, formData_773243, nil)

var postCreateJob* = Call_PostCreateJob_773224(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_773225, base: "/", url: url_PostCreateJob_773226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_773205 = ref object of OpenApiRestCall_772581
proc url_GetCreateJob_773207(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateJob_773206(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: JString (required)
  ##   ManifestAddendum: JString
  ##                   : For internal use only.
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773208 = query.getOrDefault("SignatureMethod")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = nil)
  if valid_773208 != nil:
    section.add "SignatureMethod", valid_773208
  var valid_773209 = query.getOrDefault("Manifest")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = nil)
  if valid_773209 != nil:
    section.add "Manifest", valid_773209
  var valid_773210 = query.getOrDefault("APIVersion")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "APIVersion", valid_773210
  var valid_773211 = query.getOrDefault("Signature")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = nil)
  if valid_773211 != nil:
    section.add "Signature", valid_773211
  var valid_773212 = query.getOrDefault("Action")
  valid_773212 = validateParameter(valid_773212, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_773212 != nil:
    section.add "Action", valid_773212
  var valid_773213 = query.getOrDefault("JobType")
  valid_773213 = validateParameter(valid_773213, JString, required = true,
                                 default = newJString("Import"))
  if valid_773213 != nil:
    section.add "JobType", valid_773213
  var valid_773214 = query.getOrDefault("ValidateOnly")
  valid_773214 = validateParameter(valid_773214, JBool, required = true, default = nil)
  if valid_773214 != nil:
    section.add "ValidateOnly", valid_773214
  var valid_773215 = query.getOrDefault("Timestamp")
  valid_773215 = validateParameter(valid_773215, JString, required = true,
                                 default = nil)
  if valid_773215 != nil:
    section.add "Timestamp", valid_773215
  var valid_773216 = query.getOrDefault("ManifestAddendum")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "ManifestAddendum", valid_773216
  var valid_773217 = query.getOrDefault("Operation")
  valid_773217 = validateParameter(valid_773217, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_773217 != nil:
    section.add "Operation", valid_773217
  var valid_773218 = query.getOrDefault("SignatureVersion")
  valid_773218 = validateParameter(valid_773218, JString, required = true,
                                 default = nil)
  if valid_773218 != nil:
    section.add "SignatureVersion", valid_773218
  var valid_773219 = query.getOrDefault("AWSAccessKeyId")
  valid_773219 = validateParameter(valid_773219, JString, required = true,
                                 default = nil)
  if valid_773219 != nil:
    section.add "AWSAccessKeyId", valid_773219
  var valid_773220 = query.getOrDefault("Version")
  valid_773220 = validateParameter(valid_773220, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773220 != nil:
    section.add "Version", valid_773220
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773221: Call_GetCreateJob_773205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_773221.validator(path, query, header, formData, body)
  let scheme = call_773221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773221.url(scheme.get, call_773221.host, call_773221.base,
                         call_773221.route, valid.getOrDefault("path"))
  result = hook(call_773221, url, valid)

proc call*(call_773222: Call_GetCreateJob_773205; SignatureMethod: string;
          Manifest: string; Signature: string; ValidateOnly: bool; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; APIVersion: string = "";
          Action: string = "CreateJob"; JobType: string = "Import";
          ManifestAddendum: string = ""; Operation: string = "CreateJob";
          Version: string = "2010-06-01"): Recallable =
  ## getCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   SignatureMethod: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: string (required)
  ##   ManifestAddendum: string
  ##                   : For internal use only.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_773223 = newJObject()
  add(query_773223, "SignatureMethod", newJString(SignatureMethod))
  add(query_773223, "Manifest", newJString(Manifest))
  add(query_773223, "APIVersion", newJString(APIVersion))
  add(query_773223, "Signature", newJString(Signature))
  add(query_773223, "Action", newJString(Action))
  add(query_773223, "JobType", newJString(JobType))
  add(query_773223, "ValidateOnly", newJBool(ValidateOnly))
  add(query_773223, "Timestamp", newJString(Timestamp))
  add(query_773223, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_773223, "Operation", newJString(Operation))
  add(query_773223, "SignatureVersion", newJString(SignatureVersion))
  add(query_773223, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773223, "Version", newJString(Version))
  result = call_773222.call(nil, query_773223, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_773205(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_773206, base: "/", url: url_GetCreateJob_773207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_773270 = ref object of OpenApiRestCall_772581
proc url_PostGetShippingLabel_773272(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetShippingLabel_773271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773273 = query.getOrDefault("SignatureMethod")
  valid_773273 = validateParameter(valid_773273, JString, required = true,
                                 default = nil)
  if valid_773273 != nil:
    section.add "SignatureMethod", valid_773273
  var valid_773274 = query.getOrDefault("Signature")
  valid_773274 = validateParameter(valid_773274, JString, required = true,
                                 default = nil)
  if valid_773274 != nil:
    section.add "Signature", valid_773274
  var valid_773275 = query.getOrDefault("Action")
  valid_773275 = validateParameter(valid_773275, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_773275 != nil:
    section.add "Action", valid_773275
  var valid_773276 = query.getOrDefault("Timestamp")
  valid_773276 = validateParameter(valid_773276, JString, required = true,
                                 default = nil)
  if valid_773276 != nil:
    section.add "Timestamp", valid_773276
  var valid_773277 = query.getOrDefault("Operation")
  valid_773277 = validateParameter(valid_773277, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_773277 != nil:
    section.add "Operation", valid_773277
  var valid_773278 = query.getOrDefault("SignatureVersion")
  valid_773278 = validateParameter(valid_773278, JString, required = true,
                                 default = nil)
  if valid_773278 != nil:
    section.add "SignatureVersion", valid_773278
  var valid_773279 = query.getOrDefault("AWSAccessKeyId")
  valid_773279 = validateParameter(valid_773279, JString, required = true,
                                 default = nil)
  if valid_773279 != nil:
    section.add "AWSAccessKeyId", valid_773279
  var valid_773280 = query.getOrDefault("Version")
  valid_773280 = validateParameter(valid_773280, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773280 != nil:
    section.add "Version", valid_773280
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   company: JString
  ##          : Specifies the name of the company that will ship this package.
  ##   stateOrProvince: JString
  ##                  : Specifies the name of your state or your province for the return address.
  ##   street1: JString
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   name: JString
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   street3: JString
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   city: JString
  ##       : Specifies the name of your city for the return address.
  ##   postalCode: JString
  ##             : Specifies the postal code for the return address.
  ##   phoneNumber: JString
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   street2: JString
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   country: JString
  ##          : Specifies the name of your country for the return address.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   jobIds: JArray (required)
  section = newJObject()
  var valid_773281 = formData.getOrDefault("company")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "company", valid_773281
  var valid_773282 = formData.getOrDefault("stateOrProvince")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "stateOrProvince", valid_773282
  var valid_773283 = formData.getOrDefault("street1")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "street1", valid_773283
  var valid_773284 = formData.getOrDefault("name")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "name", valid_773284
  var valid_773285 = formData.getOrDefault("street3")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "street3", valid_773285
  var valid_773286 = formData.getOrDefault("city")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "city", valid_773286
  var valid_773287 = formData.getOrDefault("postalCode")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "postalCode", valid_773287
  var valid_773288 = formData.getOrDefault("phoneNumber")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "phoneNumber", valid_773288
  var valid_773289 = formData.getOrDefault("street2")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "street2", valid_773289
  var valid_773290 = formData.getOrDefault("country")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "country", valid_773290
  var valid_773291 = formData.getOrDefault("APIVersion")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "APIVersion", valid_773291
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_773292 = formData.getOrDefault("jobIds")
  valid_773292 = validateParameter(valid_773292, JArray, required = true, default = nil)
  if valid_773292 != nil:
    section.add "jobIds", valid_773292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773293: Call_PostGetShippingLabel_773270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_773293.validator(path, query, header, formData, body)
  let scheme = call_773293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773293.url(scheme.get, call_773293.host, call_773293.base,
                         call_773293.route, valid.getOrDefault("path"))
  result = hook(call_773293, url, valid)

proc call*(call_773294: Call_PostGetShippingLabel_773270; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; jobIds: JsonNode; company: string = "";
          stateOrProvince: string = ""; street1: string = ""; name: string = "";
          street3: string = ""; Action: string = "GetShippingLabel"; city: string = "";
          postalCode: string = ""; Operation: string = "GetShippingLabel";
          phoneNumber: string = ""; street2: string = "";
          Version: string = "2010-06-01"; country: string = ""; APIVersion: string = ""): Recallable =
  ## postGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   company: string
  ##          : Specifies the name of the company that will ship this package.
  ##   SignatureMethod: string (required)
  ##   stateOrProvince: string
  ##                  : Specifies the name of your state or your province for the return address.
  ##   Signature: string (required)
  ##   street1: string
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   name: string
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   street3: string
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   Action: string (required)
  ##   city: string
  ##       : Specifies the name of your city for the return address.
  ##   Timestamp: string (required)
  ##   postalCode: string
  ##             : Specifies the postal code for the return address.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   phoneNumber: string
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   AWSAccessKeyId: string (required)
  ##   street2: string
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   Version: string (required)
  ##   country: string
  ##          : Specifies the name of your country for the return address.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   jobIds: JArray (required)
  var query_773295 = newJObject()
  var formData_773296 = newJObject()
  add(formData_773296, "company", newJString(company))
  add(query_773295, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773296, "stateOrProvince", newJString(stateOrProvince))
  add(query_773295, "Signature", newJString(Signature))
  add(formData_773296, "street1", newJString(street1))
  add(formData_773296, "name", newJString(name))
  add(formData_773296, "street3", newJString(street3))
  add(query_773295, "Action", newJString(Action))
  add(formData_773296, "city", newJString(city))
  add(query_773295, "Timestamp", newJString(Timestamp))
  add(formData_773296, "postalCode", newJString(postalCode))
  add(query_773295, "Operation", newJString(Operation))
  add(query_773295, "SignatureVersion", newJString(SignatureVersion))
  add(formData_773296, "phoneNumber", newJString(phoneNumber))
  add(query_773295, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_773296, "street2", newJString(street2))
  add(query_773295, "Version", newJString(Version))
  add(formData_773296, "country", newJString(country))
  add(formData_773296, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_773296.add "jobIds", jobIds
  result = call_773294.call(nil, query_773295, nil, formData_773296, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_773270(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_773271, base: "/",
    url: url_PostGetShippingLabel_773272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_773244 = ref object of OpenApiRestCall_772581
proc url_GetGetShippingLabel_773246(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetShippingLabel_773245(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   city: JString
  ##       : Specifies the name of your city for the return address.
  ##   country: JString
  ##          : Specifies the name of your country for the return address.
  ##   stateOrProvince: JString
  ##                  : Specifies the name of your state or your province for the return address.
  ##   company: JString
  ##          : Specifies the name of the company that will ship this package.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   phoneNumber: JString
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   street1: JString
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   Signature: JString (required)
  ##   street3: JString
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   Action: JString (required)
  ##   name: JString
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   jobIds: JArray (required)
  ##   AWSAccessKeyId: JString (required)
  ##   street2: JString
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   postalCode: JString
  ##             : Specifies the postal code for the return address.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773247 = query.getOrDefault("SignatureMethod")
  valid_773247 = validateParameter(valid_773247, JString, required = true,
                                 default = nil)
  if valid_773247 != nil:
    section.add "SignatureMethod", valid_773247
  var valid_773248 = query.getOrDefault("city")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "city", valid_773248
  var valid_773249 = query.getOrDefault("country")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "country", valid_773249
  var valid_773250 = query.getOrDefault("stateOrProvince")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "stateOrProvince", valid_773250
  var valid_773251 = query.getOrDefault("company")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "company", valid_773251
  var valid_773252 = query.getOrDefault("APIVersion")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "APIVersion", valid_773252
  var valid_773253 = query.getOrDefault("phoneNumber")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "phoneNumber", valid_773253
  var valid_773254 = query.getOrDefault("street1")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "street1", valid_773254
  var valid_773255 = query.getOrDefault("Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = true,
                                 default = nil)
  if valid_773255 != nil:
    section.add "Signature", valid_773255
  var valid_773256 = query.getOrDefault("street3")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "street3", valid_773256
  var valid_773257 = query.getOrDefault("Action")
  valid_773257 = validateParameter(valid_773257, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_773257 != nil:
    section.add "Action", valid_773257
  var valid_773258 = query.getOrDefault("name")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "name", valid_773258
  var valid_773259 = query.getOrDefault("Timestamp")
  valid_773259 = validateParameter(valid_773259, JString, required = true,
                                 default = nil)
  if valid_773259 != nil:
    section.add "Timestamp", valid_773259
  var valid_773260 = query.getOrDefault("Operation")
  valid_773260 = validateParameter(valid_773260, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_773260 != nil:
    section.add "Operation", valid_773260
  var valid_773261 = query.getOrDefault("SignatureVersion")
  valid_773261 = validateParameter(valid_773261, JString, required = true,
                                 default = nil)
  if valid_773261 != nil:
    section.add "SignatureVersion", valid_773261
  var valid_773262 = query.getOrDefault("jobIds")
  valid_773262 = validateParameter(valid_773262, JArray, required = true, default = nil)
  if valid_773262 != nil:
    section.add "jobIds", valid_773262
  var valid_773263 = query.getOrDefault("AWSAccessKeyId")
  valid_773263 = validateParameter(valid_773263, JString, required = true,
                                 default = nil)
  if valid_773263 != nil:
    section.add "AWSAccessKeyId", valid_773263
  var valid_773264 = query.getOrDefault("street2")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "street2", valid_773264
  var valid_773265 = query.getOrDefault("postalCode")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "postalCode", valid_773265
  var valid_773266 = query.getOrDefault("Version")
  valid_773266 = validateParameter(valid_773266, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773266 != nil:
    section.add "Version", valid_773266
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773267: Call_GetGetShippingLabel_773244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_773267.validator(path, query, header, formData, body)
  let scheme = call_773267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773267.url(scheme.get, call_773267.host, call_773267.base,
                         call_773267.route, valid.getOrDefault("path"))
  result = hook(call_773267, url, valid)

proc call*(call_773268: Call_GetGetShippingLabel_773244; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          jobIds: JsonNode; AWSAccessKeyId: string; city: string = "";
          country: string = ""; stateOrProvince: string = ""; company: string = "";
          APIVersion: string = ""; phoneNumber: string = ""; street1: string = "";
          street3: string = ""; Action: string = "GetShippingLabel"; name: string = "";
          Operation: string = "GetShippingLabel"; street2: string = "";
          postalCode: string = ""; Version: string = "2010-06-01"): Recallable =
  ## getGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   SignatureMethod: string (required)
  ##   city: string
  ##       : Specifies the name of your city for the return address.
  ##   country: string
  ##          : Specifies the name of your country for the return address.
  ##   stateOrProvince: string
  ##                  : Specifies the name of your state or your province for the return address.
  ##   company: string
  ##          : Specifies the name of the company that will ship this package.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   phoneNumber: string
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   street1: string
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   Signature: string (required)
  ##   street3: string
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   Action: string (required)
  ##   name: string
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   jobIds: JArray (required)
  ##   AWSAccessKeyId: string (required)
  ##   street2: string
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   postalCode: string
  ##             : Specifies the postal code for the return address.
  ##   Version: string (required)
  var query_773269 = newJObject()
  add(query_773269, "SignatureMethod", newJString(SignatureMethod))
  add(query_773269, "city", newJString(city))
  add(query_773269, "country", newJString(country))
  add(query_773269, "stateOrProvince", newJString(stateOrProvince))
  add(query_773269, "company", newJString(company))
  add(query_773269, "APIVersion", newJString(APIVersion))
  add(query_773269, "phoneNumber", newJString(phoneNumber))
  add(query_773269, "street1", newJString(street1))
  add(query_773269, "Signature", newJString(Signature))
  add(query_773269, "street3", newJString(street3))
  add(query_773269, "Action", newJString(Action))
  add(query_773269, "name", newJString(name))
  add(query_773269, "Timestamp", newJString(Timestamp))
  add(query_773269, "Operation", newJString(Operation))
  add(query_773269, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_773269.add "jobIds", jobIds
  add(query_773269, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773269, "street2", newJString(street2))
  add(query_773269, "postalCode", newJString(postalCode))
  add(query_773269, "Version", newJString(Version))
  result = call_773268.call(nil, query_773269, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_773244(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_773245, base: "/",
    url: url_GetGetShippingLabel_773246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_773313 = ref object of OpenApiRestCall_772581
proc url_PostGetStatus_773315(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetStatus_773314(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773316 = query.getOrDefault("SignatureMethod")
  valid_773316 = validateParameter(valid_773316, JString, required = true,
                                 default = nil)
  if valid_773316 != nil:
    section.add "SignatureMethod", valid_773316
  var valid_773317 = query.getOrDefault("Signature")
  valid_773317 = validateParameter(valid_773317, JString, required = true,
                                 default = nil)
  if valid_773317 != nil:
    section.add "Signature", valid_773317
  var valid_773318 = query.getOrDefault("Action")
  valid_773318 = validateParameter(valid_773318, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_773318 != nil:
    section.add "Action", valid_773318
  var valid_773319 = query.getOrDefault("Timestamp")
  valid_773319 = validateParameter(valid_773319, JString, required = true,
                                 default = nil)
  if valid_773319 != nil:
    section.add "Timestamp", valid_773319
  var valid_773320 = query.getOrDefault("Operation")
  valid_773320 = validateParameter(valid_773320, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_773320 != nil:
    section.add "Operation", valid_773320
  var valid_773321 = query.getOrDefault("SignatureVersion")
  valid_773321 = validateParameter(valid_773321, JString, required = true,
                                 default = nil)
  if valid_773321 != nil:
    section.add "SignatureVersion", valid_773321
  var valid_773322 = query.getOrDefault("AWSAccessKeyId")
  valid_773322 = validateParameter(valid_773322, JString, required = true,
                                 default = nil)
  if valid_773322 != nil:
    section.add "AWSAccessKeyId", valid_773322
  var valid_773323 = query.getOrDefault("Version")
  valid_773323 = validateParameter(valid_773323, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773323 != nil:
    section.add "Version", valid_773323
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_773324 = formData.getOrDefault("JobId")
  valid_773324 = validateParameter(valid_773324, JString, required = true,
                                 default = nil)
  if valid_773324 != nil:
    section.add "JobId", valid_773324
  var valid_773325 = formData.getOrDefault("APIVersion")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "APIVersion", valid_773325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773326: Call_PostGetStatus_773313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_773326.validator(path, query, header, formData, body)
  let scheme = call_773326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773326.url(scheme.get, call_773326.host, call_773326.base,
                         call_773326.route, valid.getOrDefault("path"))
  result = hook(call_773326, url, valid)

proc call*(call_773327: Call_PostGetStatus_773313; SignatureMethod: string;
          Signature: string; Timestamp: string; JobId: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "GetStatus"; Operation: string = "GetStatus";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_773328 = newJObject()
  var formData_773329 = newJObject()
  add(query_773328, "SignatureMethod", newJString(SignatureMethod))
  add(query_773328, "Signature", newJString(Signature))
  add(query_773328, "Action", newJString(Action))
  add(query_773328, "Timestamp", newJString(Timestamp))
  add(formData_773329, "JobId", newJString(JobId))
  add(query_773328, "Operation", newJString(Operation))
  add(query_773328, "SignatureVersion", newJString(SignatureVersion))
  add(query_773328, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773328, "Version", newJString(Version))
  add(formData_773329, "APIVersion", newJString(APIVersion))
  result = call_773327.call(nil, query_773328, nil, formData_773329, nil)

var postGetStatus* = Call_PostGetStatus_773313(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_773314, base: "/", url: url_PostGetStatus_773315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_773297 = ref object of OpenApiRestCall_772581
proc url_GetGetStatus_773299(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetStatus_773298(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773300 = query.getOrDefault("SignatureMethod")
  valid_773300 = validateParameter(valid_773300, JString, required = true,
                                 default = nil)
  if valid_773300 != nil:
    section.add "SignatureMethod", valid_773300
  var valid_773301 = query.getOrDefault("JobId")
  valid_773301 = validateParameter(valid_773301, JString, required = true,
                                 default = nil)
  if valid_773301 != nil:
    section.add "JobId", valid_773301
  var valid_773302 = query.getOrDefault("APIVersion")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "APIVersion", valid_773302
  var valid_773303 = query.getOrDefault("Signature")
  valid_773303 = validateParameter(valid_773303, JString, required = true,
                                 default = nil)
  if valid_773303 != nil:
    section.add "Signature", valid_773303
  var valid_773304 = query.getOrDefault("Action")
  valid_773304 = validateParameter(valid_773304, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_773304 != nil:
    section.add "Action", valid_773304
  var valid_773305 = query.getOrDefault("Timestamp")
  valid_773305 = validateParameter(valid_773305, JString, required = true,
                                 default = nil)
  if valid_773305 != nil:
    section.add "Timestamp", valid_773305
  var valid_773306 = query.getOrDefault("Operation")
  valid_773306 = validateParameter(valid_773306, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_773306 != nil:
    section.add "Operation", valid_773306
  var valid_773307 = query.getOrDefault("SignatureVersion")
  valid_773307 = validateParameter(valid_773307, JString, required = true,
                                 default = nil)
  if valid_773307 != nil:
    section.add "SignatureVersion", valid_773307
  var valid_773308 = query.getOrDefault("AWSAccessKeyId")
  valid_773308 = validateParameter(valid_773308, JString, required = true,
                                 default = nil)
  if valid_773308 != nil:
    section.add "AWSAccessKeyId", valid_773308
  var valid_773309 = query.getOrDefault("Version")
  valid_773309 = validateParameter(valid_773309, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773309 != nil:
    section.add "Version", valid_773309
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773310: Call_GetGetStatus_773297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_773310.validator(path, query, header, formData, body)
  let scheme = call_773310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773310.url(scheme.get, call_773310.host, call_773310.base,
                         call_773310.route, valid.getOrDefault("path"))
  result = hook(call_773310, url, valid)

proc call*(call_773311: Call_GetGetStatus_773297; SignatureMethod: string;
          JobId: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; APIVersion: string = "";
          Action: string = "GetStatus"; Operation: string = "GetStatus";
          Version: string = "2010-06-01"): Recallable =
  ## getGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   SignatureMethod: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_773312 = newJObject()
  add(query_773312, "SignatureMethod", newJString(SignatureMethod))
  add(query_773312, "JobId", newJString(JobId))
  add(query_773312, "APIVersion", newJString(APIVersion))
  add(query_773312, "Signature", newJString(Signature))
  add(query_773312, "Action", newJString(Action))
  add(query_773312, "Timestamp", newJString(Timestamp))
  add(query_773312, "Operation", newJString(Operation))
  add(query_773312, "SignatureVersion", newJString(SignatureVersion))
  add(query_773312, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773312, "Version", newJString(Version))
  result = call_773311.call(nil, query_773312, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_773297(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_773298, base: "/", url: url_GetGetStatus_773299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_773347 = ref object of OpenApiRestCall_772581
proc url_PostListJobs_773349(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListJobs_773348(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773350 = query.getOrDefault("SignatureMethod")
  valid_773350 = validateParameter(valid_773350, JString, required = true,
                                 default = nil)
  if valid_773350 != nil:
    section.add "SignatureMethod", valid_773350
  var valid_773351 = query.getOrDefault("Signature")
  valid_773351 = validateParameter(valid_773351, JString, required = true,
                                 default = nil)
  if valid_773351 != nil:
    section.add "Signature", valid_773351
  var valid_773352 = query.getOrDefault("Action")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_773352 != nil:
    section.add "Action", valid_773352
  var valid_773353 = query.getOrDefault("Timestamp")
  valid_773353 = validateParameter(valid_773353, JString, required = true,
                                 default = nil)
  if valid_773353 != nil:
    section.add "Timestamp", valid_773353
  var valid_773354 = query.getOrDefault("Operation")
  valid_773354 = validateParameter(valid_773354, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_773354 != nil:
    section.add "Operation", valid_773354
  var valid_773355 = query.getOrDefault("SignatureVersion")
  valid_773355 = validateParameter(valid_773355, JString, required = true,
                                 default = nil)
  if valid_773355 != nil:
    section.add "SignatureVersion", valid_773355
  var valid_773356 = query.getOrDefault("AWSAccessKeyId")
  valid_773356 = validateParameter(valid_773356, JString, required = true,
                                 default = nil)
  if valid_773356 != nil:
    section.add "AWSAccessKeyId", valid_773356
  var valid_773357 = query.getOrDefault("Version")
  valid_773357 = validateParameter(valid_773357, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773357 != nil:
    section.add "Version", valid_773357
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   MaxJobs: JInt
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  var valid_773358 = formData.getOrDefault("Marker")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "Marker", valid_773358
  var valid_773359 = formData.getOrDefault("MaxJobs")
  valid_773359 = validateParameter(valid_773359, JInt, required = false, default = nil)
  if valid_773359 != nil:
    section.add "MaxJobs", valid_773359
  var valid_773360 = formData.getOrDefault("APIVersion")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "APIVersion", valid_773360
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773361: Call_PostListJobs_773347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_773361.validator(path, query, header, formData, body)
  let scheme = call_773361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773361.url(scheme.get, call_773361.host, call_773361.base,
                         call_773361.route, valid.getOrDefault("path"))
  result = hook(call_773361, url, valid)

proc call*(call_773362: Call_PostListJobs_773347; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; Marker: string = ""; Action: string = "ListJobs";
          MaxJobs: int = 0; Operation: string = "ListJobs";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Marker: string
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Action: string (required)
  ##   MaxJobs: int
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_773363 = newJObject()
  var formData_773364 = newJObject()
  add(query_773363, "SignatureMethod", newJString(SignatureMethod))
  add(query_773363, "Signature", newJString(Signature))
  add(formData_773364, "Marker", newJString(Marker))
  add(query_773363, "Action", newJString(Action))
  add(formData_773364, "MaxJobs", newJInt(MaxJobs))
  add(query_773363, "Timestamp", newJString(Timestamp))
  add(query_773363, "Operation", newJString(Operation))
  add(query_773363, "SignatureVersion", newJString(SignatureVersion))
  add(query_773363, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773363, "Version", newJString(Version))
  add(formData_773364, "APIVersion", newJString(APIVersion))
  result = call_773362.call(nil, query_773363, nil, formData_773364, nil)

var postListJobs* = Call_PostListJobs_773347(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_773348, base: "/", url: url_PostListJobs_773349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_773330 = ref object of OpenApiRestCall_772581
proc url_GetListJobs_773332(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListJobs_773331(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   MaxJobs: JInt
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773333 = query.getOrDefault("SignatureMethod")
  valid_773333 = validateParameter(valid_773333, JString, required = true,
                                 default = nil)
  if valid_773333 != nil:
    section.add "SignatureMethod", valid_773333
  var valid_773334 = query.getOrDefault("APIVersion")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "APIVersion", valid_773334
  var valid_773335 = query.getOrDefault("Signature")
  valid_773335 = validateParameter(valid_773335, JString, required = true,
                                 default = nil)
  if valid_773335 != nil:
    section.add "Signature", valid_773335
  var valid_773336 = query.getOrDefault("MaxJobs")
  valid_773336 = validateParameter(valid_773336, JInt, required = false, default = nil)
  if valid_773336 != nil:
    section.add "MaxJobs", valid_773336
  var valid_773337 = query.getOrDefault("Action")
  valid_773337 = validateParameter(valid_773337, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_773337 != nil:
    section.add "Action", valid_773337
  var valid_773338 = query.getOrDefault("Marker")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "Marker", valid_773338
  var valid_773339 = query.getOrDefault("Timestamp")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = nil)
  if valid_773339 != nil:
    section.add "Timestamp", valid_773339
  var valid_773340 = query.getOrDefault("Operation")
  valid_773340 = validateParameter(valid_773340, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_773340 != nil:
    section.add "Operation", valid_773340
  var valid_773341 = query.getOrDefault("SignatureVersion")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = nil)
  if valid_773341 != nil:
    section.add "SignatureVersion", valid_773341
  var valid_773342 = query.getOrDefault("AWSAccessKeyId")
  valid_773342 = validateParameter(valid_773342, JString, required = true,
                                 default = nil)
  if valid_773342 != nil:
    section.add "AWSAccessKeyId", valid_773342
  var valid_773343 = query.getOrDefault("Version")
  valid_773343 = validateParameter(valid_773343, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773343 != nil:
    section.add "Version", valid_773343
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773344: Call_GetListJobs_773330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_773344.validator(path, query, header, formData, body)
  let scheme = call_773344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773344.url(scheme.get, call_773344.host, call_773344.base,
                         call_773344.route, valid.getOrDefault("path"))
  result = hook(call_773344, url, valid)

proc call*(call_773345: Call_GetListJobs_773330; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; APIVersion: string = ""; MaxJobs: int = 0;
          Action: string = "ListJobs"; Marker: string = "";
          Operation: string = "ListJobs"; Version: string = "2010-06-01"): Recallable =
  ## getListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   SignatureMethod: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   MaxJobs: int
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Action: string (required)
  ##   Marker: string
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_773346 = newJObject()
  add(query_773346, "SignatureMethod", newJString(SignatureMethod))
  add(query_773346, "APIVersion", newJString(APIVersion))
  add(query_773346, "Signature", newJString(Signature))
  add(query_773346, "MaxJobs", newJInt(MaxJobs))
  add(query_773346, "Action", newJString(Action))
  add(query_773346, "Marker", newJString(Marker))
  add(query_773346, "Timestamp", newJString(Timestamp))
  add(query_773346, "Operation", newJString(Operation))
  add(query_773346, "SignatureVersion", newJString(SignatureVersion))
  add(query_773346, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773346, "Version", newJString(Version))
  result = call_773345.call(nil, query_773346, nil, nil, nil)

var getListJobs* = Call_GetListJobs_773330(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_773331,
                                        base: "/", url: url_GetListJobs_773332,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_773384 = ref object of OpenApiRestCall_772581
proc url_PostUpdateJob_773386(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateJob_773385(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773387 = query.getOrDefault("SignatureMethod")
  valid_773387 = validateParameter(valid_773387, JString, required = true,
                                 default = nil)
  if valid_773387 != nil:
    section.add "SignatureMethod", valid_773387
  var valid_773388 = query.getOrDefault("Signature")
  valid_773388 = validateParameter(valid_773388, JString, required = true,
                                 default = nil)
  if valid_773388 != nil:
    section.add "Signature", valid_773388
  var valid_773389 = query.getOrDefault("Action")
  valid_773389 = validateParameter(valid_773389, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_773389 != nil:
    section.add "Action", valid_773389
  var valid_773390 = query.getOrDefault("Timestamp")
  valid_773390 = validateParameter(valid_773390, JString, required = true,
                                 default = nil)
  if valid_773390 != nil:
    section.add "Timestamp", valid_773390
  var valid_773391 = query.getOrDefault("Operation")
  valid_773391 = validateParameter(valid_773391, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_773391 != nil:
    section.add "Operation", valid_773391
  var valid_773392 = query.getOrDefault("SignatureVersion")
  valid_773392 = validateParameter(valid_773392, JString, required = true,
                                 default = nil)
  if valid_773392 != nil:
    section.add "SignatureVersion", valid_773392
  var valid_773393 = query.getOrDefault("AWSAccessKeyId")
  valid_773393 = validateParameter(valid_773393, JString, required = true,
                                 default = nil)
  if valid_773393 != nil:
    section.add "AWSAccessKeyId", valid_773393
  var valid_773394 = query.getOrDefault("Version")
  valid_773394 = validateParameter(valid_773394, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773394 != nil:
    section.add "Version", valid_773394
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_773395 = formData.getOrDefault("Manifest")
  valid_773395 = validateParameter(valid_773395, JString, required = true,
                                 default = nil)
  if valid_773395 != nil:
    section.add "Manifest", valid_773395
  var valid_773396 = formData.getOrDefault("JobType")
  valid_773396 = validateParameter(valid_773396, JString, required = true,
                                 default = newJString("Import"))
  if valid_773396 != nil:
    section.add "JobType", valid_773396
  var valid_773397 = formData.getOrDefault("JobId")
  valid_773397 = validateParameter(valid_773397, JString, required = true,
                                 default = nil)
  if valid_773397 != nil:
    section.add "JobId", valid_773397
  var valid_773398 = formData.getOrDefault("ValidateOnly")
  valid_773398 = validateParameter(valid_773398, JBool, required = true, default = nil)
  if valid_773398 != nil:
    section.add "ValidateOnly", valid_773398
  var valid_773399 = formData.getOrDefault("APIVersion")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "APIVersion", valid_773399
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773400: Call_PostUpdateJob_773384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_773400.validator(path, query, header, formData, body)
  let scheme = call_773400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773400.url(scheme.get, call_773400.host, call_773400.base,
                         call_773400.route, valid.getOrDefault("path"))
  result = hook(call_773400, url, valid)

proc call*(call_773401: Call_PostUpdateJob_773384; SignatureMethod: string;
          Signature: string; Manifest: string; Timestamp: string; JobId: string;
          SignatureVersion: string; AWSAccessKeyId: string; ValidateOnly: bool;
          JobType: string = "Import"; Action: string = "UpdateJob";
          Operation: string = "UpdateJob"; Version: string = "2010-06-01";
          APIVersion: string = ""): Recallable =
  ## postUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_773402 = newJObject()
  var formData_773403 = newJObject()
  add(query_773402, "SignatureMethod", newJString(SignatureMethod))
  add(query_773402, "Signature", newJString(Signature))
  add(formData_773403, "Manifest", newJString(Manifest))
  add(formData_773403, "JobType", newJString(JobType))
  add(query_773402, "Action", newJString(Action))
  add(query_773402, "Timestamp", newJString(Timestamp))
  add(formData_773403, "JobId", newJString(JobId))
  add(query_773402, "Operation", newJString(Operation))
  add(query_773402, "SignatureVersion", newJString(SignatureVersion))
  add(query_773402, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773402, "Version", newJString(Version))
  add(formData_773403, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_773403, "APIVersion", newJString(APIVersion))
  result = call_773401.call(nil, query_773402, nil, formData_773403, nil)

var postUpdateJob* = Call_PostUpdateJob_773384(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_773385, base: "/", url: url_PostUpdateJob_773386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_773365 = ref object of OpenApiRestCall_772581
proc url_GetUpdateJob_773367(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateJob_773366(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_773368 = query.getOrDefault("SignatureMethod")
  valid_773368 = validateParameter(valid_773368, JString, required = true,
                                 default = nil)
  if valid_773368 != nil:
    section.add "SignatureMethod", valid_773368
  var valid_773369 = query.getOrDefault("Manifest")
  valid_773369 = validateParameter(valid_773369, JString, required = true,
                                 default = nil)
  if valid_773369 != nil:
    section.add "Manifest", valid_773369
  var valid_773370 = query.getOrDefault("JobId")
  valid_773370 = validateParameter(valid_773370, JString, required = true,
                                 default = nil)
  if valid_773370 != nil:
    section.add "JobId", valid_773370
  var valid_773371 = query.getOrDefault("APIVersion")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "APIVersion", valid_773371
  var valid_773372 = query.getOrDefault("Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = true,
                                 default = nil)
  if valid_773372 != nil:
    section.add "Signature", valid_773372
  var valid_773373 = query.getOrDefault("Action")
  valid_773373 = validateParameter(valid_773373, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_773373 != nil:
    section.add "Action", valid_773373
  var valid_773374 = query.getOrDefault("JobType")
  valid_773374 = validateParameter(valid_773374, JString, required = true,
                                 default = newJString("Import"))
  if valid_773374 != nil:
    section.add "JobType", valid_773374
  var valid_773375 = query.getOrDefault("ValidateOnly")
  valid_773375 = validateParameter(valid_773375, JBool, required = true, default = nil)
  if valid_773375 != nil:
    section.add "ValidateOnly", valid_773375
  var valid_773376 = query.getOrDefault("Timestamp")
  valid_773376 = validateParameter(valid_773376, JString, required = true,
                                 default = nil)
  if valid_773376 != nil:
    section.add "Timestamp", valid_773376
  var valid_773377 = query.getOrDefault("Operation")
  valid_773377 = validateParameter(valid_773377, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_773377 != nil:
    section.add "Operation", valid_773377
  var valid_773378 = query.getOrDefault("SignatureVersion")
  valid_773378 = validateParameter(valid_773378, JString, required = true,
                                 default = nil)
  if valid_773378 != nil:
    section.add "SignatureVersion", valid_773378
  var valid_773379 = query.getOrDefault("AWSAccessKeyId")
  valid_773379 = validateParameter(valid_773379, JString, required = true,
                                 default = nil)
  if valid_773379 != nil:
    section.add "AWSAccessKeyId", valid_773379
  var valid_773380 = query.getOrDefault("Version")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_773380 != nil:
    section.add "Version", valid_773380
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773381: Call_GetUpdateJob_773365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_773381.validator(path, query, header, formData, body)
  let scheme = call_773381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773381.url(scheme.get, call_773381.host, call_773381.base,
                         call_773381.route, valid.getOrDefault("path"))
  result = hook(call_773381, url, valid)

proc call*(call_773382: Call_GetUpdateJob_773365; SignatureMethod: string;
          Manifest: string; JobId: string; Signature: string; ValidateOnly: bool;
          Timestamp: string; SignatureVersion: string; AWSAccessKeyId: string;
          APIVersion: string = ""; Action: string = "UpdateJob";
          JobType: string = "Import"; Operation: string = "UpdateJob";
          Version: string = "2010-06-01"): Recallable =
  ## getUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   SignatureMethod: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_773383 = newJObject()
  add(query_773383, "SignatureMethod", newJString(SignatureMethod))
  add(query_773383, "Manifest", newJString(Manifest))
  add(query_773383, "JobId", newJString(JobId))
  add(query_773383, "APIVersion", newJString(APIVersion))
  add(query_773383, "Signature", newJString(Signature))
  add(query_773383, "Action", newJString(Action))
  add(query_773383, "JobType", newJString(JobType))
  add(query_773383, "ValidateOnly", newJBool(ValidateOnly))
  add(query_773383, "Timestamp", newJString(Timestamp))
  add(query_773383, "Operation", newJString(Operation))
  add(query_773383, "SignatureVersion", newJString(SignatureVersion))
  add(query_773383, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773383, "Version", newJString(Version))
  result = call_773382.call(nil, query_773383, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_773365(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_773366, base: "/", url: url_GetUpdateJob_773367,
    schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
