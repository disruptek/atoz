
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_600421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600421): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "importexport"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCancelJob_601029 = ref object of OpenApiRestCall_600421
proc url_PostCancelJob_601031(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCancelJob_601030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601032 = query.getOrDefault("SignatureMethod")
  valid_601032 = validateParameter(valid_601032, JString, required = true,
                                 default = nil)
  if valid_601032 != nil:
    section.add "SignatureMethod", valid_601032
  var valid_601033 = query.getOrDefault("Signature")
  valid_601033 = validateParameter(valid_601033, JString, required = true,
                                 default = nil)
  if valid_601033 != nil:
    section.add "Signature", valid_601033
  var valid_601034 = query.getOrDefault("Action")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601034 != nil:
    section.add "Action", valid_601034
  var valid_601035 = query.getOrDefault("Timestamp")
  valid_601035 = validateParameter(valid_601035, JString, required = true,
                                 default = nil)
  if valid_601035 != nil:
    section.add "Timestamp", valid_601035
  var valid_601036 = query.getOrDefault("Operation")
  valid_601036 = validateParameter(valid_601036, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601036 != nil:
    section.add "Operation", valid_601036
  var valid_601037 = query.getOrDefault("SignatureVersion")
  valid_601037 = validateParameter(valid_601037, JString, required = true,
                                 default = nil)
  if valid_601037 != nil:
    section.add "SignatureVersion", valid_601037
  var valid_601038 = query.getOrDefault("AWSAccessKeyId")
  valid_601038 = validateParameter(valid_601038, JString, required = true,
                                 default = nil)
  if valid_601038 != nil:
    section.add "AWSAccessKeyId", valid_601038
  var valid_601039 = query.getOrDefault("Version")
  valid_601039 = validateParameter(valid_601039, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601039 != nil:
    section.add "Version", valid_601039
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
  var valid_601040 = formData.getOrDefault("JobId")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = nil)
  if valid_601040 != nil:
    section.add "JobId", valid_601040
  var valid_601041 = formData.getOrDefault("APIVersion")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "APIVersion", valid_601041
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601042: Call_PostCancelJob_601029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_601042.validator(path, query, header, formData, body)
  let scheme = call_601042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601042.url(scheme.get, call_601042.host, call_601042.base,
                         call_601042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601042, url, valid)

proc call*(call_601043: Call_PostCancelJob_601029; SignatureMethod: string;
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
  var query_601044 = newJObject()
  var formData_601045 = newJObject()
  add(query_601044, "SignatureMethod", newJString(SignatureMethod))
  add(query_601044, "Signature", newJString(Signature))
  add(query_601044, "Action", newJString(Action))
  add(query_601044, "Timestamp", newJString(Timestamp))
  add(formData_601045, "JobId", newJString(JobId))
  add(query_601044, "Operation", newJString(Operation))
  add(query_601044, "SignatureVersion", newJString(SignatureVersion))
  add(query_601044, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601044, "Version", newJString(Version))
  add(formData_601045, "APIVersion", newJString(APIVersion))
  result = call_601043.call(nil, query_601044, nil, formData_601045, nil)

var postCancelJob* = Call_PostCancelJob_601029(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_601030, base: "/", url: url_PostCancelJob_601031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_600758 = ref object of OpenApiRestCall_600421
proc url_GetCancelJob_600760(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCancelJob_600759(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600872 = query.getOrDefault("SignatureMethod")
  valid_600872 = validateParameter(valid_600872, JString, required = true,
                                 default = nil)
  if valid_600872 != nil:
    section.add "SignatureMethod", valid_600872
  var valid_600873 = query.getOrDefault("JobId")
  valid_600873 = validateParameter(valid_600873, JString, required = true,
                                 default = nil)
  if valid_600873 != nil:
    section.add "JobId", valid_600873
  var valid_600874 = query.getOrDefault("APIVersion")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "APIVersion", valid_600874
  var valid_600875 = query.getOrDefault("Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = true,
                                 default = nil)
  if valid_600875 != nil:
    section.add "Signature", valid_600875
  var valid_600889 = query.getOrDefault("Action")
  valid_600889 = validateParameter(valid_600889, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_600889 != nil:
    section.add "Action", valid_600889
  var valid_600890 = query.getOrDefault("Timestamp")
  valid_600890 = validateParameter(valid_600890, JString, required = true,
                                 default = nil)
  if valid_600890 != nil:
    section.add "Timestamp", valid_600890
  var valid_600891 = query.getOrDefault("Operation")
  valid_600891 = validateParameter(valid_600891, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_600891 != nil:
    section.add "Operation", valid_600891
  var valid_600892 = query.getOrDefault("SignatureVersion")
  valid_600892 = validateParameter(valid_600892, JString, required = true,
                                 default = nil)
  if valid_600892 != nil:
    section.add "SignatureVersion", valid_600892
  var valid_600893 = query.getOrDefault("AWSAccessKeyId")
  valid_600893 = validateParameter(valid_600893, JString, required = true,
                                 default = nil)
  if valid_600893 != nil:
    section.add "AWSAccessKeyId", valid_600893
  var valid_600894 = query.getOrDefault("Version")
  valid_600894 = validateParameter(valid_600894, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600894 != nil:
    section.add "Version", valid_600894
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600917: Call_GetCancelJob_600758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_600917.validator(path, query, header, formData, body)
  let scheme = call_600917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600917.url(scheme.get, call_600917.host, call_600917.base,
                         call_600917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600917, url, valid)

proc call*(call_600988: Call_GetCancelJob_600758; SignatureMethod: string;
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
  var query_600989 = newJObject()
  add(query_600989, "SignatureMethod", newJString(SignatureMethod))
  add(query_600989, "JobId", newJString(JobId))
  add(query_600989, "APIVersion", newJString(APIVersion))
  add(query_600989, "Signature", newJString(Signature))
  add(query_600989, "Action", newJString(Action))
  add(query_600989, "Timestamp", newJString(Timestamp))
  add(query_600989, "Operation", newJString(Operation))
  add(query_600989, "SignatureVersion", newJString(SignatureVersion))
  add(query_600989, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600989, "Version", newJString(Version))
  result = call_600988.call(nil, query_600989, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_600758(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_600759, base: "/", url: url_GetCancelJob_600760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_601065 = ref object of OpenApiRestCall_600421
proc url_PostCreateJob_601067(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateJob_601066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601068 = query.getOrDefault("SignatureMethod")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = nil)
  if valid_601068 != nil:
    section.add "SignatureMethod", valid_601068
  var valid_601069 = query.getOrDefault("Signature")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = nil)
  if valid_601069 != nil:
    section.add "Signature", valid_601069
  var valid_601070 = query.getOrDefault("Action")
  valid_601070 = validateParameter(valid_601070, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601070 != nil:
    section.add "Action", valid_601070
  var valid_601071 = query.getOrDefault("Timestamp")
  valid_601071 = validateParameter(valid_601071, JString, required = true,
                                 default = nil)
  if valid_601071 != nil:
    section.add "Timestamp", valid_601071
  var valid_601072 = query.getOrDefault("Operation")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601072 != nil:
    section.add "Operation", valid_601072
  var valid_601073 = query.getOrDefault("SignatureVersion")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "SignatureVersion", valid_601073
  var valid_601074 = query.getOrDefault("AWSAccessKeyId")
  valid_601074 = validateParameter(valid_601074, JString, required = true,
                                 default = nil)
  if valid_601074 != nil:
    section.add "AWSAccessKeyId", valid_601074
  var valid_601075 = query.getOrDefault("Version")
  valid_601075 = validateParameter(valid_601075, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601075 != nil:
    section.add "Version", valid_601075
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
  var valid_601076 = formData.getOrDefault("ManifestAddendum")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "ManifestAddendum", valid_601076
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_601077 = formData.getOrDefault("Manifest")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = nil)
  if valid_601077 != nil:
    section.add "Manifest", valid_601077
  var valid_601078 = formData.getOrDefault("JobType")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = newJString("Import"))
  if valid_601078 != nil:
    section.add "JobType", valid_601078
  var valid_601079 = formData.getOrDefault("ValidateOnly")
  valid_601079 = validateParameter(valid_601079, JBool, required = true, default = nil)
  if valid_601079 != nil:
    section.add "ValidateOnly", valid_601079
  var valid_601080 = formData.getOrDefault("APIVersion")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "APIVersion", valid_601080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601081: Call_PostCreateJob_601065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_601081.validator(path, query, header, formData, body)
  let scheme = call_601081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601081.url(scheme.get, call_601081.host, call_601081.base,
                         call_601081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601081, url, valid)

proc call*(call_601082: Call_PostCreateJob_601065; SignatureMethod: string;
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
  var query_601083 = newJObject()
  var formData_601084 = newJObject()
  add(query_601083, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601084, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_601083, "Signature", newJString(Signature))
  add(formData_601084, "Manifest", newJString(Manifest))
  add(formData_601084, "JobType", newJString(JobType))
  add(query_601083, "Action", newJString(Action))
  add(query_601083, "Timestamp", newJString(Timestamp))
  add(query_601083, "Operation", newJString(Operation))
  add(query_601083, "SignatureVersion", newJString(SignatureVersion))
  add(query_601083, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601083, "Version", newJString(Version))
  add(formData_601084, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_601084, "APIVersion", newJString(APIVersion))
  result = call_601082.call(nil, query_601083, nil, formData_601084, nil)

var postCreateJob* = Call_PostCreateJob_601065(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_601066, base: "/", url: url_PostCreateJob_601067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_601046 = ref object of OpenApiRestCall_600421
proc url_GetCreateJob_601048(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateJob_601047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601049 = query.getOrDefault("SignatureMethod")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = nil)
  if valid_601049 != nil:
    section.add "SignatureMethod", valid_601049
  var valid_601050 = query.getOrDefault("Manifest")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = nil)
  if valid_601050 != nil:
    section.add "Manifest", valid_601050
  var valid_601051 = query.getOrDefault("APIVersion")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "APIVersion", valid_601051
  var valid_601052 = query.getOrDefault("Signature")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "Signature", valid_601052
  var valid_601053 = query.getOrDefault("Action")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601053 != nil:
    section.add "Action", valid_601053
  var valid_601054 = query.getOrDefault("JobType")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = newJString("Import"))
  if valid_601054 != nil:
    section.add "JobType", valid_601054
  var valid_601055 = query.getOrDefault("ValidateOnly")
  valid_601055 = validateParameter(valid_601055, JBool, required = true, default = nil)
  if valid_601055 != nil:
    section.add "ValidateOnly", valid_601055
  var valid_601056 = query.getOrDefault("Timestamp")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "Timestamp", valid_601056
  var valid_601057 = query.getOrDefault("ManifestAddendum")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "ManifestAddendum", valid_601057
  var valid_601058 = query.getOrDefault("Operation")
  valid_601058 = validateParameter(valid_601058, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601058 != nil:
    section.add "Operation", valid_601058
  var valid_601059 = query.getOrDefault("SignatureVersion")
  valid_601059 = validateParameter(valid_601059, JString, required = true,
                                 default = nil)
  if valid_601059 != nil:
    section.add "SignatureVersion", valid_601059
  var valid_601060 = query.getOrDefault("AWSAccessKeyId")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = nil)
  if valid_601060 != nil:
    section.add "AWSAccessKeyId", valid_601060
  var valid_601061 = query.getOrDefault("Version")
  valid_601061 = validateParameter(valid_601061, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601061 != nil:
    section.add "Version", valid_601061
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_GetCreateJob_601046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_GetCreateJob_601046; SignatureMethod: string;
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
  var query_601064 = newJObject()
  add(query_601064, "SignatureMethod", newJString(SignatureMethod))
  add(query_601064, "Manifest", newJString(Manifest))
  add(query_601064, "APIVersion", newJString(APIVersion))
  add(query_601064, "Signature", newJString(Signature))
  add(query_601064, "Action", newJString(Action))
  add(query_601064, "JobType", newJString(JobType))
  add(query_601064, "ValidateOnly", newJBool(ValidateOnly))
  add(query_601064, "Timestamp", newJString(Timestamp))
  add(query_601064, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_601064, "Operation", newJString(Operation))
  add(query_601064, "SignatureVersion", newJString(SignatureVersion))
  add(query_601064, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601064, "Version", newJString(Version))
  result = call_601063.call(nil, query_601064, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_601046(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_601047, base: "/", url: url_GetCreateJob_601048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_601111 = ref object of OpenApiRestCall_600421
proc url_PostGetShippingLabel_601113(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetShippingLabel_601112(path: JsonNode; query: JsonNode;
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
  var valid_601114 = query.getOrDefault("SignatureMethod")
  valid_601114 = validateParameter(valid_601114, JString, required = true,
                                 default = nil)
  if valid_601114 != nil:
    section.add "SignatureMethod", valid_601114
  var valid_601115 = query.getOrDefault("Signature")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = nil)
  if valid_601115 != nil:
    section.add "Signature", valid_601115
  var valid_601116 = query.getOrDefault("Action")
  valid_601116 = validateParameter(valid_601116, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601116 != nil:
    section.add "Action", valid_601116
  var valid_601117 = query.getOrDefault("Timestamp")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = nil)
  if valid_601117 != nil:
    section.add "Timestamp", valid_601117
  var valid_601118 = query.getOrDefault("Operation")
  valid_601118 = validateParameter(valid_601118, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601118 != nil:
    section.add "Operation", valid_601118
  var valid_601119 = query.getOrDefault("SignatureVersion")
  valid_601119 = validateParameter(valid_601119, JString, required = true,
                                 default = nil)
  if valid_601119 != nil:
    section.add "SignatureVersion", valid_601119
  var valid_601120 = query.getOrDefault("AWSAccessKeyId")
  valid_601120 = validateParameter(valid_601120, JString, required = true,
                                 default = nil)
  if valid_601120 != nil:
    section.add "AWSAccessKeyId", valid_601120
  var valid_601121 = query.getOrDefault("Version")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601121 != nil:
    section.add "Version", valid_601121
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
  var valid_601122 = formData.getOrDefault("company")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "company", valid_601122
  var valid_601123 = formData.getOrDefault("stateOrProvince")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "stateOrProvince", valid_601123
  var valid_601124 = formData.getOrDefault("street1")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "street1", valid_601124
  var valid_601125 = formData.getOrDefault("name")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "name", valid_601125
  var valid_601126 = formData.getOrDefault("street3")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "street3", valid_601126
  var valid_601127 = formData.getOrDefault("city")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "city", valid_601127
  var valid_601128 = formData.getOrDefault("postalCode")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "postalCode", valid_601128
  var valid_601129 = formData.getOrDefault("phoneNumber")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "phoneNumber", valid_601129
  var valid_601130 = formData.getOrDefault("street2")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "street2", valid_601130
  var valid_601131 = formData.getOrDefault("country")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "country", valid_601131
  var valid_601132 = formData.getOrDefault("APIVersion")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "APIVersion", valid_601132
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_601133 = formData.getOrDefault("jobIds")
  valid_601133 = validateParameter(valid_601133, JArray, required = true, default = nil)
  if valid_601133 != nil:
    section.add "jobIds", valid_601133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601134: Call_PostGetShippingLabel_601111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_601134.validator(path, query, header, formData, body)
  let scheme = call_601134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601134.url(scheme.get, call_601134.host, call_601134.base,
                         call_601134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601134, url, valid)

proc call*(call_601135: Call_PostGetShippingLabel_601111; SignatureMethod: string;
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
  var query_601136 = newJObject()
  var formData_601137 = newJObject()
  add(formData_601137, "company", newJString(company))
  add(query_601136, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601137, "stateOrProvince", newJString(stateOrProvince))
  add(query_601136, "Signature", newJString(Signature))
  add(formData_601137, "street1", newJString(street1))
  add(formData_601137, "name", newJString(name))
  add(formData_601137, "street3", newJString(street3))
  add(query_601136, "Action", newJString(Action))
  add(formData_601137, "city", newJString(city))
  add(query_601136, "Timestamp", newJString(Timestamp))
  add(formData_601137, "postalCode", newJString(postalCode))
  add(query_601136, "Operation", newJString(Operation))
  add(query_601136, "SignatureVersion", newJString(SignatureVersion))
  add(formData_601137, "phoneNumber", newJString(phoneNumber))
  add(query_601136, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_601137, "street2", newJString(street2))
  add(query_601136, "Version", newJString(Version))
  add(formData_601137, "country", newJString(country))
  add(formData_601137, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_601137.add "jobIds", jobIds
  result = call_601135.call(nil, query_601136, nil, formData_601137, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_601111(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_601112, base: "/",
    url: url_PostGetShippingLabel_601113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_601085 = ref object of OpenApiRestCall_600421
proc url_GetGetShippingLabel_601087(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetShippingLabel_601086(path: JsonNode; query: JsonNode;
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
  var valid_601088 = query.getOrDefault("SignatureMethod")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = nil)
  if valid_601088 != nil:
    section.add "SignatureMethod", valid_601088
  var valid_601089 = query.getOrDefault("city")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "city", valid_601089
  var valid_601090 = query.getOrDefault("country")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "country", valid_601090
  var valid_601091 = query.getOrDefault("stateOrProvince")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "stateOrProvince", valid_601091
  var valid_601092 = query.getOrDefault("company")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "company", valid_601092
  var valid_601093 = query.getOrDefault("APIVersion")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "APIVersion", valid_601093
  var valid_601094 = query.getOrDefault("phoneNumber")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "phoneNumber", valid_601094
  var valid_601095 = query.getOrDefault("street1")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "street1", valid_601095
  var valid_601096 = query.getOrDefault("Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = true,
                                 default = nil)
  if valid_601096 != nil:
    section.add "Signature", valid_601096
  var valid_601097 = query.getOrDefault("street3")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "street3", valid_601097
  var valid_601098 = query.getOrDefault("Action")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601098 != nil:
    section.add "Action", valid_601098
  var valid_601099 = query.getOrDefault("name")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "name", valid_601099
  var valid_601100 = query.getOrDefault("Timestamp")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = nil)
  if valid_601100 != nil:
    section.add "Timestamp", valid_601100
  var valid_601101 = query.getOrDefault("Operation")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601101 != nil:
    section.add "Operation", valid_601101
  var valid_601102 = query.getOrDefault("SignatureVersion")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = nil)
  if valid_601102 != nil:
    section.add "SignatureVersion", valid_601102
  var valid_601103 = query.getOrDefault("jobIds")
  valid_601103 = validateParameter(valid_601103, JArray, required = true, default = nil)
  if valid_601103 != nil:
    section.add "jobIds", valid_601103
  var valid_601104 = query.getOrDefault("AWSAccessKeyId")
  valid_601104 = validateParameter(valid_601104, JString, required = true,
                                 default = nil)
  if valid_601104 != nil:
    section.add "AWSAccessKeyId", valid_601104
  var valid_601105 = query.getOrDefault("street2")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "street2", valid_601105
  var valid_601106 = query.getOrDefault("postalCode")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "postalCode", valid_601106
  var valid_601107 = query.getOrDefault("Version")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601107 != nil:
    section.add "Version", valid_601107
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601108: Call_GetGetShippingLabel_601085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_601108.validator(path, query, header, formData, body)
  let scheme = call_601108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601108.url(scheme.get, call_601108.host, call_601108.base,
                         call_601108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601108, url, valid)

proc call*(call_601109: Call_GetGetShippingLabel_601085; SignatureMethod: string;
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
  var query_601110 = newJObject()
  add(query_601110, "SignatureMethod", newJString(SignatureMethod))
  add(query_601110, "city", newJString(city))
  add(query_601110, "country", newJString(country))
  add(query_601110, "stateOrProvince", newJString(stateOrProvince))
  add(query_601110, "company", newJString(company))
  add(query_601110, "APIVersion", newJString(APIVersion))
  add(query_601110, "phoneNumber", newJString(phoneNumber))
  add(query_601110, "street1", newJString(street1))
  add(query_601110, "Signature", newJString(Signature))
  add(query_601110, "street3", newJString(street3))
  add(query_601110, "Action", newJString(Action))
  add(query_601110, "name", newJString(name))
  add(query_601110, "Timestamp", newJString(Timestamp))
  add(query_601110, "Operation", newJString(Operation))
  add(query_601110, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_601110.add "jobIds", jobIds
  add(query_601110, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601110, "street2", newJString(street2))
  add(query_601110, "postalCode", newJString(postalCode))
  add(query_601110, "Version", newJString(Version))
  result = call_601109.call(nil, query_601110, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_601085(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_601086, base: "/",
    url: url_GetGetShippingLabel_601087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_601154 = ref object of OpenApiRestCall_600421
proc url_PostGetStatus_601156(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetStatus_601155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601157 = query.getOrDefault("SignatureMethod")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = nil)
  if valid_601157 != nil:
    section.add "SignatureMethod", valid_601157
  var valid_601158 = query.getOrDefault("Signature")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = nil)
  if valid_601158 != nil:
    section.add "Signature", valid_601158
  var valid_601159 = query.getOrDefault("Action")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601159 != nil:
    section.add "Action", valid_601159
  var valid_601160 = query.getOrDefault("Timestamp")
  valid_601160 = validateParameter(valid_601160, JString, required = true,
                                 default = nil)
  if valid_601160 != nil:
    section.add "Timestamp", valid_601160
  var valid_601161 = query.getOrDefault("Operation")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601161 != nil:
    section.add "Operation", valid_601161
  var valid_601162 = query.getOrDefault("SignatureVersion")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = nil)
  if valid_601162 != nil:
    section.add "SignatureVersion", valid_601162
  var valid_601163 = query.getOrDefault("AWSAccessKeyId")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "AWSAccessKeyId", valid_601163
  var valid_601164 = query.getOrDefault("Version")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601164 != nil:
    section.add "Version", valid_601164
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
  var valid_601165 = formData.getOrDefault("JobId")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "JobId", valid_601165
  var valid_601166 = formData.getOrDefault("APIVersion")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "APIVersion", valid_601166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_PostGetStatus_601154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601167, url, valid)

proc call*(call_601168: Call_PostGetStatus_601154; SignatureMethod: string;
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
  var query_601169 = newJObject()
  var formData_601170 = newJObject()
  add(query_601169, "SignatureMethod", newJString(SignatureMethod))
  add(query_601169, "Signature", newJString(Signature))
  add(query_601169, "Action", newJString(Action))
  add(query_601169, "Timestamp", newJString(Timestamp))
  add(formData_601170, "JobId", newJString(JobId))
  add(query_601169, "Operation", newJString(Operation))
  add(query_601169, "SignatureVersion", newJString(SignatureVersion))
  add(query_601169, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601169, "Version", newJString(Version))
  add(formData_601170, "APIVersion", newJString(APIVersion))
  result = call_601168.call(nil, query_601169, nil, formData_601170, nil)

var postGetStatus* = Call_PostGetStatus_601154(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_601155, base: "/", url: url_PostGetStatus_601156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_601138 = ref object of OpenApiRestCall_600421
proc url_GetGetStatus_601140(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetStatus_601139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601141 = query.getOrDefault("SignatureMethod")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = nil)
  if valid_601141 != nil:
    section.add "SignatureMethod", valid_601141
  var valid_601142 = query.getOrDefault("JobId")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "JobId", valid_601142
  var valid_601143 = query.getOrDefault("APIVersion")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "APIVersion", valid_601143
  var valid_601144 = query.getOrDefault("Signature")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = nil)
  if valid_601144 != nil:
    section.add "Signature", valid_601144
  var valid_601145 = query.getOrDefault("Action")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601145 != nil:
    section.add "Action", valid_601145
  var valid_601146 = query.getOrDefault("Timestamp")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = nil)
  if valid_601146 != nil:
    section.add "Timestamp", valid_601146
  var valid_601147 = query.getOrDefault("Operation")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601147 != nil:
    section.add "Operation", valid_601147
  var valid_601148 = query.getOrDefault("SignatureVersion")
  valid_601148 = validateParameter(valid_601148, JString, required = true,
                                 default = nil)
  if valid_601148 != nil:
    section.add "SignatureVersion", valid_601148
  var valid_601149 = query.getOrDefault("AWSAccessKeyId")
  valid_601149 = validateParameter(valid_601149, JString, required = true,
                                 default = nil)
  if valid_601149 != nil:
    section.add "AWSAccessKeyId", valid_601149
  var valid_601150 = query.getOrDefault("Version")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601150 != nil:
    section.add "Version", valid_601150
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601151: Call_GetGetStatus_601138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_601151.validator(path, query, header, formData, body)
  let scheme = call_601151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601151.url(scheme.get, call_601151.host, call_601151.base,
                         call_601151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601151, url, valid)

proc call*(call_601152: Call_GetGetStatus_601138; SignatureMethod: string;
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
  var query_601153 = newJObject()
  add(query_601153, "SignatureMethod", newJString(SignatureMethod))
  add(query_601153, "JobId", newJString(JobId))
  add(query_601153, "APIVersion", newJString(APIVersion))
  add(query_601153, "Signature", newJString(Signature))
  add(query_601153, "Action", newJString(Action))
  add(query_601153, "Timestamp", newJString(Timestamp))
  add(query_601153, "Operation", newJString(Operation))
  add(query_601153, "SignatureVersion", newJString(SignatureVersion))
  add(query_601153, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601153, "Version", newJString(Version))
  result = call_601152.call(nil, query_601153, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_601138(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_601139, base: "/", url: url_GetGetStatus_601140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_601188 = ref object of OpenApiRestCall_600421
proc url_PostListJobs_601190(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListJobs_601189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601191 = query.getOrDefault("SignatureMethod")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = nil)
  if valid_601191 != nil:
    section.add "SignatureMethod", valid_601191
  var valid_601192 = query.getOrDefault("Signature")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = nil)
  if valid_601192 != nil:
    section.add "Signature", valid_601192
  var valid_601193 = query.getOrDefault("Action")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601193 != nil:
    section.add "Action", valid_601193
  var valid_601194 = query.getOrDefault("Timestamp")
  valid_601194 = validateParameter(valid_601194, JString, required = true,
                                 default = nil)
  if valid_601194 != nil:
    section.add "Timestamp", valid_601194
  var valid_601195 = query.getOrDefault("Operation")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601195 != nil:
    section.add "Operation", valid_601195
  var valid_601196 = query.getOrDefault("SignatureVersion")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = nil)
  if valid_601196 != nil:
    section.add "SignatureVersion", valid_601196
  var valid_601197 = query.getOrDefault("AWSAccessKeyId")
  valid_601197 = validateParameter(valid_601197, JString, required = true,
                                 default = nil)
  if valid_601197 != nil:
    section.add "AWSAccessKeyId", valid_601197
  var valid_601198 = query.getOrDefault("Version")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601198 != nil:
    section.add "Version", valid_601198
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
  var valid_601199 = formData.getOrDefault("Marker")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "Marker", valid_601199
  var valid_601200 = formData.getOrDefault("MaxJobs")
  valid_601200 = validateParameter(valid_601200, JInt, required = false, default = nil)
  if valid_601200 != nil:
    section.add "MaxJobs", valid_601200
  var valid_601201 = formData.getOrDefault("APIVersion")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "APIVersion", valid_601201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601202: Call_PostListJobs_601188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_601202.validator(path, query, header, formData, body)
  let scheme = call_601202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601202.url(scheme.get, call_601202.host, call_601202.base,
                         call_601202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601202, url, valid)

proc call*(call_601203: Call_PostListJobs_601188; SignatureMethod: string;
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
  var query_601204 = newJObject()
  var formData_601205 = newJObject()
  add(query_601204, "SignatureMethod", newJString(SignatureMethod))
  add(query_601204, "Signature", newJString(Signature))
  add(formData_601205, "Marker", newJString(Marker))
  add(query_601204, "Action", newJString(Action))
  add(formData_601205, "MaxJobs", newJInt(MaxJobs))
  add(query_601204, "Timestamp", newJString(Timestamp))
  add(query_601204, "Operation", newJString(Operation))
  add(query_601204, "SignatureVersion", newJString(SignatureVersion))
  add(query_601204, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601204, "Version", newJString(Version))
  add(formData_601205, "APIVersion", newJString(APIVersion))
  result = call_601203.call(nil, query_601204, nil, formData_601205, nil)

var postListJobs* = Call_PostListJobs_601188(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_601189, base: "/", url: url_PostListJobs_601190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_601171 = ref object of OpenApiRestCall_600421
proc url_GetListJobs_601173(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListJobs_601172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601174 = query.getOrDefault("SignatureMethod")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "SignatureMethod", valid_601174
  var valid_601175 = query.getOrDefault("APIVersion")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "APIVersion", valid_601175
  var valid_601176 = query.getOrDefault("Signature")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "Signature", valid_601176
  var valid_601177 = query.getOrDefault("MaxJobs")
  valid_601177 = validateParameter(valid_601177, JInt, required = false, default = nil)
  if valid_601177 != nil:
    section.add "MaxJobs", valid_601177
  var valid_601178 = query.getOrDefault("Action")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601178 != nil:
    section.add "Action", valid_601178
  var valid_601179 = query.getOrDefault("Marker")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "Marker", valid_601179
  var valid_601180 = query.getOrDefault("Timestamp")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = nil)
  if valid_601180 != nil:
    section.add "Timestamp", valid_601180
  var valid_601181 = query.getOrDefault("Operation")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601181 != nil:
    section.add "Operation", valid_601181
  var valid_601182 = query.getOrDefault("SignatureVersion")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = nil)
  if valid_601182 != nil:
    section.add "SignatureVersion", valid_601182
  var valid_601183 = query.getOrDefault("AWSAccessKeyId")
  valid_601183 = validateParameter(valid_601183, JString, required = true,
                                 default = nil)
  if valid_601183 != nil:
    section.add "AWSAccessKeyId", valid_601183
  var valid_601184 = query.getOrDefault("Version")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601184 != nil:
    section.add "Version", valid_601184
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601185: Call_GetListJobs_601171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_601185.validator(path, query, header, formData, body)
  let scheme = call_601185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601185.url(scheme.get, call_601185.host, call_601185.base,
                         call_601185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601185, url, valid)

proc call*(call_601186: Call_GetListJobs_601171; SignatureMethod: string;
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
  var query_601187 = newJObject()
  add(query_601187, "SignatureMethod", newJString(SignatureMethod))
  add(query_601187, "APIVersion", newJString(APIVersion))
  add(query_601187, "Signature", newJString(Signature))
  add(query_601187, "MaxJobs", newJInt(MaxJobs))
  add(query_601187, "Action", newJString(Action))
  add(query_601187, "Marker", newJString(Marker))
  add(query_601187, "Timestamp", newJString(Timestamp))
  add(query_601187, "Operation", newJString(Operation))
  add(query_601187, "SignatureVersion", newJString(SignatureVersion))
  add(query_601187, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601187, "Version", newJString(Version))
  result = call_601186.call(nil, query_601187, nil, nil, nil)

var getListJobs* = Call_GetListJobs_601171(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_601172,
                                        base: "/", url: url_GetListJobs_601173,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_601225 = ref object of OpenApiRestCall_600421
proc url_PostUpdateJob_601227(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateJob_601226(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601228 = query.getOrDefault("SignatureMethod")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = nil)
  if valid_601228 != nil:
    section.add "SignatureMethod", valid_601228
  var valid_601229 = query.getOrDefault("Signature")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = nil)
  if valid_601229 != nil:
    section.add "Signature", valid_601229
  var valid_601230 = query.getOrDefault("Action")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601230 != nil:
    section.add "Action", valid_601230
  var valid_601231 = query.getOrDefault("Timestamp")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "Timestamp", valid_601231
  var valid_601232 = query.getOrDefault("Operation")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601232 != nil:
    section.add "Operation", valid_601232
  var valid_601233 = query.getOrDefault("SignatureVersion")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "SignatureVersion", valid_601233
  var valid_601234 = query.getOrDefault("AWSAccessKeyId")
  valid_601234 = validateParameter(valid_601234, JString, required = true,
                                 default = nil)
  if valid_601234 != nil:
    section.add "AWSAccessKeyId", valid_601234
  var valid_601235 = query.getOrDefault("Version")
  valid_601235 = validateParameter(valid_601235, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601235 != nil:
    section.add "Version", valid_601235
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
  var valid_601236 = formData.getOrDefault("Manifest")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = nil)
  if valid_601236 != nil:
    section.add "Manifest", valid_601236
  var valid_601237 = formData.getOrDefault("JobType")
  valid_601237 = validateParameter(valid_601237, JString, required = true,
                                 default = newJString("Import"))
  if valid_601237 != nil:
    section.add "JobType", valid_601237
  var valid_601238 = formData.getOrDefault("JobId")
  valid_601238 = validateParameter(valid_601238, JString, required = true,
                                 default = nil)
  if valid_601238 != nil:
    section.add "JobId", valid_601238
  var valid_601239 = formData.getOrDefault("ValidateOnly")
  valid_601239 = validateParameter(valid_601239, JBool, required = true, default = nil)
  if valid_601239 != nil:
    section.add "ValidateOnly", valid_601239
  var valid_601240 = formData.getOrDefault("APIVersion")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "APIVersion", valid_601240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_PostUpdateJob_601225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_PostUpdateJob_601225; SignatureMethod: string;
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
  var query_601243 = newJObject()
  var formData_601244 = newJObject()
  add(query_601243, "SignatureMethod", newJString(SignatureMethod))
  add(query_601243, "Signature", newJString(Signature))
  add(formData_601244, "Manifest", newJString(Manifest))
  add(formData_601244, "JobType", newJString(JobType))
  add(query_601243, "Action", newJString(Action))
  add(query_601243, "Timestamp", newJString(Timestamp))
  add(formData_601244, "JobId", newJString(JobId))
  add(query_601243, "Operation", newJString(Operation))
  add(query_601243, "SignatureVersion", newJString(SignatureVersion))
  add(query_601243, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601243, "Version", newJString(Version))
  add(formData_601244, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_601244, "APIVersion", newJString(APIVersion))
  result = call_601242.call(nil, query_601243, nil, formData_601244, nil)

var postUpdateJob* = Call_PostUpdateJob_601225(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_601226, base: "/", url: url_PostUpdateJob_601227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_601206 = ref object of OpenApiRestCall_600421
proc url_GetUpdateJob_601208(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateJob_601207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601209 = query.getOrDefault("SignatureMethod")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "SignatureMethod", valid_601209
  var valid_601210 = query.getOrDefault("Manifest")
  valid_601210 = validateParameter(valid_601210, JString, required = true,
                                 default = nil)
  if valid_601210 != nil:
    section.add "Manifest", valid_601210
  var valid_601211 = query.getOrDefault("JobId")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = nil)
  if valid_601211 != nil:
    section.add "JobId", valid_601211
  var valid_601212 = query.getOrDefault("APIVersion")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "APIVersion", valid_601212
  var valid_601213 = query.getOrDefault("Signature")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "Signature", valid_601213
  var valid_601214 = query.getOrDefault("Action")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601214 != nil:
    section.add "Action", valid_601214
  var valid_601215 = query.getOrDefault("JobType")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = newJString("Import"))
  if valid_601215 != nil:
    section.add "JobType", valid_601215
  var valid_601216 = query.getOrDefault("ValidateOnly")
  valid_601216 = validateParameter(valid_601216, JBool, required = true, default = nil)
  if valid_601216 != nil:
    section.add "ValidateOnly", valid_601216
  var valid_601217 = query.getOrDefault("Timestamp")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = nil)
  if valid_601217 != nil:
    section.add "Timestamp", valid_601217
  var valid_601218 = query.getOrDefault("Operation")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601218 != nil:
    section.add "Operation", valid_601218
  var valid_601219 = query.getOrDefault("SignatureVersion")
  valid_601219 = validateParameter(valid_601219, JString, required = true,
                                 default = nil)
  if valid_601219 != nil:
    section.add "SignatureVersion", valid_601219
  var valid_601220 = query.getOrDefault("AWSAccessKeyId")
  valid_601220 = validateParameter(valid_601220, JString, required = true,
                                 default = nil)
  if valid_601220 != nil:
    section.add "AWSAccessKeyId", valid_601220
  var valid_601221 = query.getOrDefault("Version")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601221 != nil:
    section.add "Version", valid_601221
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601222: Call_GetUpdateJob_601206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_601222.validator(path, query, header, formData, body)
  let scheme = call_601222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601222.url(scheme.get, call_601222.host, call_601222.base,
                         call_601222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601222, url, valid)

proc call*(call_601223: Call_GetUpdateJob_601206; SignatureMethod: string;
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
  var query_601224 = newJObject()
  add(query_601224, "SignatureMethod", newJString(SignatureMethod))
  add(query_601224, "Manifest", newJString(Manifest))
  add(query_601224, "JobId", newJString(JobId))
  add(query_601224, "APIVersion", newJString(APIVersion))
  add(query_601224, "Signature", newJString(Signature))
  add(query_601224, "Action", newJString(Action))
  add(query_601224, "JobType", newJString(JobType))
  add(query_601224, "ValidateOnly", newJBool(ValidateOnly))
  add(query_601224, "Timestamp", newJString(Timestamp))
  add(query_601224, "Operation", newJString(Operation))
  add(query_601224, "SignatureVersion", newJString(SignatureVersion))
  add(query_601224, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601224, "Version", newJString(Version))
  result = call_601223.call(nil, query_601224, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_601206(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_601207, base: "/", url: url_GetUpdateJob_601208,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
