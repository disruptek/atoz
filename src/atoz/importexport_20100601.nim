
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

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
  Call_PostCancelJob_601023 = ref object of OpenApiRestCall_600410
proc url_PostCancelJob_601025(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCancelJob_601024(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601026 = query.getOrDefault("SignatureMethod")
  valid_601026 = validateParameter(valid_601026, JString, required = true,
                                 default = nil)
  if valid_601026 != nil:
    section.add "SignatureMethod", valid_601026
  var valid_601027 = query.getOrDefault("Signature")
  valid_601027 = validateParameter(valid_601027, JString, required = true,
                                 default = nil)
  if valid_601027 != nil:
    section.add "Signature", valid_601027
  var valid_601028 = query.getOrDefault("Action")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601028 != nil:
    section.add "Action", valid_601028
  var valid_601029 = query.getOrDefault("Timestamp")
  valid_601029 = validateParameter(valid_601029, JString, required = true,
                                 default = nil)
  if valid_601029 != nil:
    section.add "Timestamp", valid_601029
  var valid_601030 = query.getOrDefault("Operation")
  valid_601030 = validateParameter(valid_601030, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601030 != nil:
    section.add "Operation", valid_601030
  var valid_601031 = query.getOrDefault("SignatureVersion")
  valid_601031 = validateParameter(valid_601031, JString, required = true,
                                 default = nil)
  if valid_601031 != nil:
    section.add "SignatureVersion", valid_601031
  var valid_601032 = query.getOrDefault("AWSAccessKeyId")
  valid_601032 = validateParameter(valid_601032, JString, required = true,
                                 default = nil)
  if valid_601032 != nil:
    section.add "AWSAccessKeyId", valid_601032
  var valid_601033 = query.getOrDefault("Version")
  valid_601033 = validateParameter(valid_601033, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601033 != nil:
    section.add "Version", valid_601033
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
  var valid_601034 = formData.getOrDefault("JobId")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "JobId", valid_601034
  var valid_601035 = formData.getOrDefault("APIVersion")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "APIVersion", valid_601035
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_PostCancelJob_601023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_PostCancelJob_601023; SignatureMethod: string;
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
  var query_601038 = newJObject()
  var formData_601039 = newJObject()
  add(query_601038, "SignatureMethod", newJString(SignatureMethod))
  add(query_601038, "Signature", newJString(Signature))
  add(query_601038, "Action", newJString(Action))
  add(query_601038, "Timestamp", newJString(Timestamp))
  add(formData_601039, "JobId", newJString(JobId))
  add(query_601038, "Operation", newJString(Operation))
  add(query_601038, "SignatureVersion", newJString(SignatureVersion))
  add(query_601038, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601038, "Version", newJString(Version))
  add(formData_601039, "APIVersion", newJString(APIVersion))
  result = call_601037.call(nil, query_601038, nil, formData_601039, nil)

var postCancelJob* = Call_PostCancelJob_601023(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_601024, base: "/", url: url_PostCancelJob_601025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_600752 = ref object of OpenApiRestCall_600410
proc url_GetCancelJob_600754(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCancelJob_600753(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600866 = query.getOrDefault("SignatureMethod")
  valid_600866 = validateParameter(valid_600866, JString, required = true,
                                 default = nil)
  if valid_600866 != nil:
    section.add "SignatureMethod", valid_600866
  var valid_600867 = query.getOrDefault("JobId")
  valid_600867 = validateParameter(valid_600867, JString, required = true,
                                 default = nil)
  if valid_600867 != nil:
    section.add "JobId", valid_600867
  var valid_600868 = query.getOrDefault("APIVersion")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "APIVersion", valid_600868
  var valid_600869 = query.getOrDefault("Signature")
  valid_600869 = validateParameter(valid_600869, JString, required = true,
                                 default = nil)
  if valid_600869 != nil:
    section.add "Signature", valid_600869
  var valid_600883 = query.getOrDefault("Action")
  valid_600883 = validateParameter(valid_600883, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_600883 != nil:
    section.add "Action", valid_600883
  var valid_600884 = query.getOrDefault("Timestamp")
  valid_600884 = validateParameter(valid_600884, JString, required = true,
                                 default = nil)
  if valid_600884 != nil:
    section.add "Timestamp", valid_600884
  var valid_600885 = query.getOrDefault("Operation")
  valid_600885 = validateParameter(valid_600885, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_600885 != nil:
    section.add "Operation", valid_600885
  var valid_600886 = query.getOrDefault("SignatureVersion")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = nil)
  if valid_600886 != nil:
    section.add "SignatureVersion", valid_600886
  var valid_600887 = query.getOrDefault("AWSAccessKeyId")
  valid_600887 = validateParameter(valid_600887, JString, required = true,
                                 default = nil)
  if valid_600887 != nil:
    section.add "AWSAccessKeyId", valid_600887
  var valid_600888 = query.getOrDefault("Version")
  valid_600888 = validateParameter(valid_600888, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600888 != nil:
    section.add "Version", valid_600888
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600911: Call_GetCancelJob_600752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_600911.validator(path, query, header, formData, body)
  let scheme = call_600911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600911.url(scheme.get, call_600911.host, call_600911.base,
                         call_600911.route, valid.getOrDefault("path"))
  result = hook(call_600911, url, valid)

proc call*(call_600982: Call_GetCancelJob_600752; SignatureMethod: string;
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
  var query_600983 = newJObject()
  add(query_600983, "SignatureMethod", newJString(SignatureMethod))
  add(query_600983, "JobId", newJString(JobId))
  add(query_600983, "APIVersion", newJString(APIVersion))
  add(query_600983, "Signature", newJString(Signature))
  add(query_600983, "Action", newJString(Action))
  add(query_600983, "Timestamp", newJString(Timestamp))
  add(query_600983, "Operation", newJString(Operation))
  add(query_600983, "SignatureVersion", newJString(SignatureVersion))
  add(query_600983, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600983, "Version", newJString(Version))
  result = call_600982.call(nil, query_600983, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_600752(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_600753, base: "/", url: url_GetCancelJob_600754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_601059 = ref object of OpenApiRestCall_600410
proc url_PostCreateJob_601061(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateJob_601060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601062 = query.getOrDefault("SignatureMethod")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "SignatureMethod", valid_601062
  var valid_601063 = query.getOrDefault("Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "Signature", valid_601063
  var valid_601064 = query.getOrDefault("Action")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601064 != nil:
    section.add "Action", valid_601064
  var valid_601065 = query.getOrDefault("Timestamp")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = nil)
  if valid_601065 != nil:
    section.add "Timestamp", valid_601065
  var valid_601066 = query.getOrDefault("Operation")
  valid_601066 = validateParameter(valid_601066, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601066 != nil:
    section.add "Operation", valid_601066
  var valid_601067 = query.getOrDefault("SignatureVersion")
  valid_601067 = validateParameter(valid_601067, JString, required = true,
                                 default = nil)
  if valid_601067 != nil:
    section.add "SignatureVersion", valid_601067
  var valid_601068 = query.getOrDefault("AWSAccessKeyId")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = nil)
  if valid_601068 != nil:
    section.add "AWSAccessKeyId", valid_601068
  var valid_601069 = query.getOrDefault("Version")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601069 != nil:
    section.add "Version", valid_601069
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
  var valid_601070 = formData.getOrDefault("ManifestAddendum")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "ManifestAddendum", valid_601070
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_601071 = formData.getOrDefault("Manifest")
  valid_601071 = validateParameter(valid_601071, JString, required = true,
                                 default = nil)
  if valid_601071 != nil:
    section.add "Manifest", valid_601071
  var valid_601072 = formData.getOrDefault("JobType")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = newJString("Import"))
  if valid_601072 != nil:
    section.add "JobType", valid_601072
  var valid_601073 = formData.getOrDefault("ValidateOnly")
  valid_601073 = validateParameter(valid_601073, JBool, required = true, default = nil)
  if valid_601073 != nil:
    section.add "ValidateOnly", valid_601073
  var valid_601074 = formData.getOrDefault("APIVersion")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "APIVersion", valid_601074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_PostCreateJob_601059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_PostCreateJob_601059; SignatureMethod: string;
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
  var query_601077 = newJObject()
  var formData_601078 = newJObject()
  add(query_601077, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601078, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_601077, "Signature", newJString(Signature))
  add(formData_601078, "Manifest", newJString(Manifest))
  add(formData_601078, "JobType", newJString(JobType))
  add(query_601077, "Action", newJString(Action))
  add(query_601077, "Timestamp", newJString(Timestamp))
  add(query_601077, "Operation", newJString(Operation))
  add(query_601077, "SignatureVersion", newJString(SignatureVersion))
  add(query_601077, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601077, "Version", newJString(Version))
  add(formData_601078, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_601078, "APIVersion", newJString(APIVersion))
  result = call_601076.call(nil, query_601077, nil, formData_601078, nil)

var postCreateJob* = Call_PostCreateJob_601059(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_601060, base: "/", url: url_PostCreateJob_601061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_601040 = ref object of OpenApiRestCall_600410
proc url_GetCreateJob_601042(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateJob_601041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601043 = query.getOrDefault("SignatureMethod")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "SignatureMethod", valid_601043
  var valid_601044 = query.getOrDefault("Manifest")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = nil)
  if valid_601044 != nil:
    section.add "Manifest", valid_601044
  var valid_601045 = query.getOrDefault("APIVersion")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "APIVersion", valid_601045
  var valid_601046 = query.getOrDefault("Signature")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = nil)
  if valid_601046 != nil:
    section.add "Signature", valid_601046
  var valid_601047 = query.getOrDefault("Action")
  valid_601047 = validateParameter(valid_601047, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601047 != nil:
    section.add "Action", valid_601047
  var valid_601048 = query.getOrDefault("JobType")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = newJString("Import"))
  if valid_601048 != nil:
    section.add "JobType", valid_601048
  var valid_601049 = query.getOrDefault("ValidateOnly")
  valid_601049 = validateParameter(valid_601049, JBool, required = true, default = nil)
  if valid_601049 != nil:
    section.add "ValidateOnly", valid_601049
  var valid_601050 = query.getOrDefault("Timestamp")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = nil)
  if valid_601050 != nil:
    section.add "Timestamp", valid_601050
  var valid_601051 = query.getOrDefault("ManifestAddendum")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "ManifestAddendum", valid_601051
  var valid_601052 = query.getOrDefault("Operation")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_601052 != nil:
    section.add "Operation", valid_601052
  var valid_601053 = query.getOrDefault("SignatureVersion")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = nil)
  if valid_601053 != nil:
    section.add "SignatureVersion", valid_601053
  var valid_601054 = query.getOrDefault("AWSAccessKeyId")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = nil)
  if valid_601054 != nil:
    section.add "AWSAccessKeyId", valid_601054
  var valid_601055 = query.getOrDefault("Version")
  valid_601055 = validateParameter(valid_601055, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601055 != nil:
    section.add "Version", valid_601055
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601056: Call_GetCreateJob_601040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_601056.validator(path, query, header, formData, body)
  let scheme = call_601056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601056.url(scheme.get, call_601056.host, call_601056.base,
                         call_601056.route, valid.getOrDefault("path"))
  result = hook(call_601056, url, valid)

proc call*(call_601057: Call_GetCreateJob_601040; SignatureMethod: string;
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
  var query_601058 = newJObject()
  add(query_601058, "SignatureMethod", newJString(SignatureMethod))
  add(query_601058, "Manifest", newJString(Manifest))
  add(query_601058, "APIVersion", newJString(APIVersion))
  add(query_601058, "Signature", newJString(Signature))
  add(query_601058, "Action", newJString(Action))
  add(query_601058, "JobType", newJString(JobType))
  add(query_601058, "ValidateOnly", newJBool(ValidateOnly))
  add(query_601058, "Timestamp", newJString(Timestamp))
  add(query_601058, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_601058, "Operation", newJString(Operation))
  add(query_601058, "SignatureVersion", newJString(SignatureVersion))
  add(query_601058, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601058, "Version", newJString(Version))
  result = call_601057.call(nil, query_601058, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_601040(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_601041, base: "/", url: url_GetCreateJob_601042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_601105 = ref object of OpenApiRestCall_600410
proc url_PostGetShippingLabel_601107(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetShippingLabel_601106(path: JsonNode; query: JsonNode;
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
  var valid_601108 = query.getOrDefault("SignatureMethod")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = nil)
  if valid_601108 != nil:
    section.add "SignatureMethod", valid_601108
  var valid_601109 = query.getOrDefault("Signature")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "Signature", valid_601109
  var valid_601110 = query.getOrDefault("Action")
  valid_601110 = validateParameter(valid_601110, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601110 != nil:
    section.add "Action", valid_601110
  var valid_601111 = query.getOrDefault("Timestamp")
  valid_601111 = validateParameter(valid_601111, JString, required = true,
                                 default = nil)
  if valid_601111 != nil:
    section.add "Timestamp", valid_601111
  var valid_601112 = query.getOrDefault("Operation")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601112 != nil:
    section.add "Operation", valid_601112
  var valid_601113 = query.getOrDefault("SignatureVersion")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = nil)
  if valid_601113 != nil:
    section.add "SignatureVersion", valid_601113
  var valid_601114 = query.getOrDefault("AWSAccessKeyId")
  valid_601114 = validateParameter(valid_601114, JString, required = true,
                                 default = nil)
  if valid_601114 != nil:
    section.add "AWSAccessKeyId", valid_601114
  var valid_601115 = query.getOrDefault("Version")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601115 != nil:
    section.add "Version", valid_601115
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
  var valid_601116 = formData.getOrDefault("company")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "company", valid_601116
  var valid_601117 = formData.getOrDefault("stateOrProvince")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "stateOrProvince", valid_601117
  var valid_601118 = formData.getOrDefault("street1")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "street1", valid_601118
  var valid_601119 = formData.getOrDefault("name")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "name", valid_601119
  var valid_601120 = formData.getOrDefault("street3")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "street3", valid_601120
  var valid_601121 = formData.getOrDefault("city")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "city", valid_601121
  var valid_601122 = formData.getOrDefault("postalCode")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "postalCode", valid_601122
  var valid_601123 = formData.getOrDefault("phoneNumber")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "phoneNumber", valid_601123
  var valid_601124 = formData.getOrDefault("street2")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "street2", valid_601124
  var valid_601125 = formData.getOrDefault("country")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "country", valid_601125
  var valid_601126 = formData.getOrDefault("APIVersion")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "APIVersion", valid_601126
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_601127 = formData.getOrDefault("jobIds")
  valid_601127 = validateParameter(valid_601127, JArray, required = true, default = nil)
  if valid_601127 != nil:
    section.add "jobIds", valid_601127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601128: Call_PostGetShippingLabel_601105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_601128.validator(path, query, header, formData, body)
  let scheme = call_601128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601128.url(scheme.get, call_601128.host, call_601128.base,
                         call_601128.route, valid.getOrDefault("path"))
  result = hook(call_601128, url, valid)

proc call*(call_601129: Call_PostGetShippingLabel_601105; SignatureMethod: string;
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
  var query_601130 = newJObject()
  var formData_601131 = newJObject()
  add(formData_601131, "company", newJString(company))
  add(query_601130, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601131, "stateOrProvince", newJString(stateOrProvince))
  add(query_601130, "Signature", newJString(Signature))
  add(formData_601131, "street1", newJString(street1))
  add(formData_601131, "name", newJString(name))
  add(formData_601131, "street3", newJString(street3))
  add(query_601130, "Action", newJString(Action))
  add(formData_601131, "city", newJString(city))
  add(query_601130, "Timestamp", newJString(Timestamp))
  add(formData_601131, "postalCode", newJString(postalCode))
  add(query_601130, "Operation", newJString(Operation))
  add(query_601130, "SignatureVersion", newJString(SignatureVersion))
  add(formData_601131, "phoneNumber", newJString(phoneNumber))
  add(query_601130, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_601131, "street2", newJString(street2))
  add(query_601130, "Version", newJString(Version))
  add(formData_601131, "country", newJString(country))
  add(formData_601131, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_601131.add "jobIds", jobIds
  result = call_601129.call(nil, query_601130, nil, formData_601131, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_601105(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_601106, base: "/",
    url: url_PostGetShippingLabel_601107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_601079 = ref object of OpenApiRestCall_600410
proc url_GetGetShippingLabel_601081(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetShippingLabel_601080(path: JsonNode; query: JsonNode;
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
  var valid_601082 = query.getOrDefault("SignatureMethod")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = nil)
  if valid_601082 != nil:
    section.add "SignatureMethod", valid_601082
  var valid_601083 = query.getOrDefault("city")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "city", valid_601083
  var valid_601084 = query.getOrDefault("country")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "country", valid_601084
  var valid_601085 = query.getOrDefault("stateOrProvince")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "stateOrProvince", valid_601085
  var valid_601086 = query.getOrDefault("company")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "company", valid_601086
  var valid_601087 = query.getOrDefault("APIVersion")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "APIVersion", valid_601087
  var valid_601088 = query.getOrDefault("phoneNumber")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "phoneNumber", valid_601088
  var valid_601089 = query.getOrDefault("street1")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "street1", valid_601089
  var valid_601090 = query.getOrDefault("Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = true,
                                 default = nil)
  if valid_601090 != nil:
    section.add "Signature", valid_601090
  var valid_601091 = query.getOrDefault("street3")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "street3", valid_601091
  var valid_601092 = query.getOrDefault("Action")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601092 != nil:
    section.add "Action", valid_601092
  var valid_601093 = query.getOrDefault("name")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "name", valid_601093
  var valid_601094 = query.getOrDefault("Timestamp")
  valid_601094 = validateParameter(valid_601094, JString, required = true,
                                 default = nil)
  if valid_601094 != nil:
    section.add "Timestamp", valid_601094
  var valid_601095 = query.getOrDefault("Operation")
  valid_601095 = validateParameter(valid_601095, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_601095 != nil:
    section.add "Operation", valid_601095
  var valid_601096 = query.getOrDefault("SignatureVersion")
  valid_601096 = validateParameter(valid_601096, JString, required = true,
                                 default = nil)
  if valid_601096 != nil:
    section.add "SignatureVersion", valid_601096
  var valid_601097 = query.getOrDefault("jobIds")
  valid_601097 = validateParameter(valid_601097, JArray, required = true, default = nil)
  if valid_601097 != nil:
    section.add "jobIds", valid_601097
  var valid_601098 = query.getOrDefault("AWSAccessKeyId")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = nil)
  if valid_601098 != nil:
    section.add "AWSAccessKeyId", valid_601098
  var valid_601099 = query.getOrDefault("street2")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "street2", valid_601099
  var valid_601100 = query.getOrDefault("postalCode")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "postalCode", valid_601100
  var valid_601101 = query.getOrDefault("Version")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601101 != nil:
    section.add "Version", valid_601101
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601102: Call_GetGetShippingLabel_601079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_601102.validator(path, query, header, formData, body)
  let scheme = call_601102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601102.url(scheme.get, call_601102.host, call_601102.base,
                         call_601102.route, valid.getOrDefault("path"))
  result = hook(call_601102, url, valid)

proc call*(call_601103: Call_GetGetShippingLabel_601079; SignatureMethod: string;
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
  var query_601104 = newJObject()
  add(query_601104, "SignatureMethod", newJString(SignatureMethod))
  add(query_601104, "city", newJString(city))
  add(query_601104, "country", newJString(country))
  add(query_601104, "stateOrProvince", newJString(stateOrProvince))
  add(query_601104, "company", newJString(company))
  add(query_601104, "APIVersion", newJString(APIVersion))
  add(query_601104, "phoneNumber", newJString(phoneNumber))
  add(query_601104, "street1", newJString(street1))
  add(query_601104, "Signature", newJString(Signature))
  add(query_601104, "street3", newJString(street3))
  add(query_601104, "Action", newJString(Action))
  add(query_601104, "name", newJString(name))
  add(query_601104, "Timestamp", newJString(Timestamp))
  add(query_601104, "Operation", newJString(Operation))
  add(query_601104, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_601104.add "jobIds", jobIds
  add(query_601104, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601104, "street2", newJString(street2))
  add(query_601104, "postalCode", newJString(postalCode))
  add(query_601104, "Version", newJString(Version))
  result = call_601103.call(nil, query_601104, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_601079(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_601080, base: "/",
    url: url_GetGetShippingLabel_601081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_601148 = ref object of OpenApiRestCall_600410
proc url_PostGetStatus_601150(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetStatus_601149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601151 = query.getOrDefault("SignatureMethod")
  valid_601151 = validateParameter(valid_601151, JString, required = true,
                                 default = nil)
  if valid_601151 != nil:
    section.add "SignatureMethod", valid_601151
  var valid_601152 = query.getOrDefault("Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = true,
                                 default = nil)
  if valid_601152 != nil:
    section.add "Signature", valid_601152
  var valid_601153 = query.getOrDefault("Action")
  valid_601153 = validateParameter(valid_601153, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601153 != nil:
    section.add "Action", valid_601153
  var valid_601154 = query.getOrDefault("Timestamp")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = nil)
  if valid_601154 != nil:
    section.add "Timestamp", valid_601154
  var valid_601155 = query.getOrDefault("Operation")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601155 != nil:
    section.add "Operation", valid_601155
  var valid_601156 = query.getOrDefault("SignatureVersion")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "SignatureVersion", valid_601156
  var valid_601157 = query.getOrDefault("AWSAccessKeyId")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = nil)
  if valid_601157 != nil:
    section.add "AWSAccessKeyId", valid_601157
  var valid_601158 = query.getOrDefault("Version")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601158 != nil:
    section.add "Version", valid_601158
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
  var valid_601159 = formData.getOrDefault("JobId")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = nil)
  if valid_601159 != nil:
    section.add "JobId", valid_601159
  var valid_601160 = formData.getOrDefault("APIVersion")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "APIVersion", valid_601160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_PostGetStatus_601148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_PostGetStatus_601148; SignatureMethod: string;
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
  var query_601163 = newJObject()
  var formData_601164 = newJObject()
  add(query_601163, "SignatureMethod", newJString(SignatureMethod))
  add(query_601163, "Signature", newJString(Signature))
  add(query_601163, "Action", newJString(Action))
  add(query_601163, "Timestamp", newJString(Timestamp))
  add(formData_601164, "JobId", newJString(JobId))
  add(query_601163, "Operation", newJString(Operation))
  add(query_601163, "SignatureVersion", newJString(SignatureVersion))
  add(query_601163, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601163, "Version", newJString(Version))
  add(formData_601164, "APIVersion", newJString(APIVersion))
  result = call_601162.call(nil, query_601163, nil, formData_601164, nil)

var postGetStatus* = Call_PostGetStatus_601148(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_601149, base: "/", url: url_PostGetStatus_601150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_601132 = ref object of OpenApiRestCall_600410
proc url_GetGetStatus_601134(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetStatus_601133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601135 = query.getOrDefault("SignatureMethod")
  valid_601135 = validateParameter(valid_601135, JString, required = true,
                                 default = nil)
  if valid_601135 != nil:
    section.add "SignatureMethod", valid_601135
  var valid_601136 = query.getOrDefault("JobId")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = nil)
  if valid_601136 != nil:
    section.add "JobId", valid_601136
  var valid_601137 = query.getOrDefault("APIVersion")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "APIVersion", valid_601137
  var valid_601138 = query.getOrDefault("Signature")
  valid_601138 = validateParameter(valid_601138, JString, required = true,
                                 default = nil)
  if valid_601138 != nil:
    section.add "Signature", valid_601138
  var valid_601139 = query.getOrDefault("Action")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601139 != nil:
    section.add "Action", valid_601139
  var valid_601140 = query.getOrDefault("Timestamp")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = nil)
  if valid_601140 != nil:
    section.add "Timestamp", valid_601140
  var valid_601141 = query.getOrDefault("Operation")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_601141 != nil:
    section.add "Operation", valid_601141
  var valid_601142 = query.getOrDefault("SignatureVersion")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "SignatureVersion", valid_601142
  var valid_601143 = query.getOrDefault("AWSAccessKeyId")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = nil)
  if valid_601143 != nil:
    section.add "AWSAccessKeyId", valid_601143
  var valid_601144 = query.getOrDefault("Version")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601144 != nil:
    section.add "Version", valid_601144
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_GetGetStatus_601132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_GetGetStatus_601132; SignatureMethod: string;
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
  var query_601147 = newJObject()
  add(query_601147, "SignatureMethod", newJString(SignatureMethod))
  add(query_601147, "JobId", newJString(JobId))
  add(query_601147, "APIVersion", newJString(APIVersion))
  add(query_601147, "Signature", newJString(Signature))
  add(query_601147, "Action", newJString(Action))
  add(query_601147, "Timestamp", newJString(Timestamp))
  add(query_601147, "Operation", newJString(Operation))
  add(query_601147, "SignatureVersion", newJString(SignatureVersion))
  add(query_601147, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601147, "Version", newJString(Version))
  result = call_601146.call(nil, query_601147, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_601132(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_601133, base: "/", url: url_GetGetStatus_601134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_601182 = ref object of OpenApiRestCall_600410
proc url_PostListJobs_601184(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListJobs_601183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601185 = query.getOrDefault("SignatureMethod")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = nil)
  if valid_601185 != nil:
    section.add "SignatureMethod", valid_601185
  var valid_601186 = query.getOrDefault("Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "Signature", valid_601186
  var valid_601187 = query.getOrDefault("Action")
  valid_601187 = validateParameter(valid_601187, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601187 != nil:
    section.add "Action", valid_601187
  var valid_601188 = query.getOrDefault("Timestamp")
  valid_601188 = validateParameter(valid_601188, JString, required = true,
                                 default = nil)
  if valid_601188 != nil:
    section.add "Timestamp", valid_601188
  var valid_601189 = query.getOrDefault("Operation")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601189 != nil:
    section.add "Operation", valid_601189
  var valid_601190 = query.getOrDefault("SignatureVersion")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = nil)
  if valid_601190 != nil:
    section.add "SignatureVersion", valid_601190
  var valid_601191 = query.getOrDefault("AWSAccessKeyId")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = nil)
  if valid_601191 != nil:
    section.add "AWSAccessKeyId", valid_601191
  var valid_601192 = query.getOrDefault("Version")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601192 != nil:
    section.add "Version", valid_601192
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
  var valid_601193 = formData.getOrDefault("Marker")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "Marker", valid_601193
  var valid_601194 = formData.getOrDefault("MaxJobs")
  valid_601194 = validateParameter(valid_601194, JInt, required = false, default = nil)
  if valid_601194 != nil:
    section.add "MaxJobs", valid_601194
  var valid_601195 = formData.getOrDefault("APIVersion")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "APIVersion", valid_601195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601196: Call_PostListJobs_601182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_601196.validator(path, query, header, formData, body)
  let scheme = call_601196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601196.url(scheme.get, call_601196.host, call_601196.base,
                         call_601196.route, valid.getOrDefault("path"))
  result = hook(call_601196, url, valid)

proc call*(call_601197: Call_PostListJobs_601182; SignatureMethod: string;
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
  var query_601198 = newJObject()
  var formData_601199 = newJObject()
  add(query_601198, "SignatureMethod", newJString(SignatureMethod))
  add(query_601198, "Signature", newJString(Signature))
  add(formData_601199, "Marker", newJString(Marker))
  add(query_601198, "Action", newJString(Action))
  add(formData_601199, "MaxJobs", newJInt(MaxJobs))
  add(query_601198, "Timestamp", newJString(Timestamp))
  add(query_601198, "Operation", newJString(Operation))
  add(query_601198, "SignatureVersion", newJString(SignatureVersion))
  add(query_601198, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601198, "Version", newJString(Version))
  add(formData_601199, "APIVersion", newJString(APIVersion))
  result = call_601197.call(nil, query_601198, nil, formData_601199, nil)

var postListJobs* = Call_PostListJobs_601182(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_601183, base: "/", url: url_PostListJobs_601184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_601165 = ref object of OpenApiRestCall_600410
proc url_GetListJobs_601167(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListJobs_601166(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601168 = query.getOrDefault("SignatureMethod")
  valid_601168 = validateParameter(valid_601168, JString, required = true,
                                 default = nil)
  if valid_601168 != nil:
    section.add "SignatureMethod", valid_601168
  var valid_601169 = query.getOrDefault("APIVersion")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "APIVersion", valid_601169
  var valid_601170 = query.getOrDefault("Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = nil)
  if valid_601170 != nil:
    section.add "Signature", valid_601170
  var valid_601171 = query.getOrDefault("MaxJobs")
  valid_601171 = validateParameter(valid_601171, JInt, required = false, default = nil)
  if valid_601171 != nil:
    section.add "MaxJobs", valid_601171
  var valid_601172 = query.getOrDefault("Action")
  valid_601172 = validateParameter(valid_601172, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601172 != nil:
    section.add "Action", valid_601172
  var valid_601173 = query.getOrDefault("Marker")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "Marker", valid_601173
  var valid_601174 = query.getOrDefault("Timestamp")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "Timestamp", valid_601174
  var valid_601175 = query.getOrDefault("Operation")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_601175 != nil:
    section.add "Operation", valid_601175
  var valid_601176 = query.getOrDefault("SignatureVersion")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "SignatureVersion", valid_601176
  var valid_601177 = query.getOrDefault("AWSAccessKeyId")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = nil)
  if valid_601177 != nil:
    section.add "AWSAccessKeyId", valid_601177
  var valid_601178 = query.getOrDefault("Version")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601178 != nil:
    section.add "Version", valid_601178
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601179: Call_GetListJobs_601165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_601179.validator(path, query, header, formData, body)
  let scheme = call_601179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601179.url(scheme.get, call_601179.host, call_601179.base,
                         call_601179.route, valid.getOrDefault("path"))
  result = hook(call_601179, url, valid)

proc call*(call_601180: Call_GetListJobs_601165; SignatureMethod: string;
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
  var query_601181 = newJObject()
  add(query_601181, "SignatureMethod", newJString(SignatureMethod))
  add(query_601181, "APIVersion", newJString(APIVersion))
  add(query_601181, "Signature", newJString(Signature))
  add(query_601181, "MaxJobs", newJInt(MaxJobs))
  add(query_601181, "Action", newJString(Action))
  add(query_601181, "Marker", newJString(Marker))
  add(query_601181, "Timestamp", newJString(Timestamp))
  add(query_601181, "Operation", newJString(Operation))
  add(query_601181, "SignatureVersion", newJString(SignatureVersion))
  add(query_601181, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601181, "Version", newJString(Version))
  result = call_601180.call(nil, query_601181, nil, nil, nil)

var getListJobs* = Call_GetListJobs_601165(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_601166,
                                        base: "/", url: url_GetListJobs_601167,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_601219 = ref object of OpenApiRestCall_600410
proc url_PostUpdateJob_601221(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateJob_601220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601222 = query.getOrDefault("SignatureMethod")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = nil)
  if valid_601222 != nil:
    section.add "SignatureMethod", valid_601222
  var valid_601223 = query.getOrDefault("Signature")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = nil)
  if valid_601223 != nil:
    section.add "Signature", valid_601223
  var valid_601224 = query.getOrDefault("Action")
  valid_601224 = validateParameter(valid_601224, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601224 != nil:
    section.add "Action", valid_601224
  var valid_601225 = query.getOrDefault("Timestamp")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "Timestamp", valid_601225
  var valid_601226 = query.getOrDefault("Operation")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601226 != nil:
    section.add "Operation", valid_601226
  var valid_601227 = query.getOrDefault("SignatureVersion")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "SignatureVersion", valid_601227
  var valid_601228 = query.getOrDefault("AWSAccessKeyId")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = nil)
  if valid_601228 != nil:
    section.add "AWSAccessKeyId", valid_601228
  var valid_601229 = query.getOrDefault("Version")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601229 != nil:
    section.add "Version", valid_601229
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
  var valid_601230 = formData.getOrDefault("Manifest")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = nil)
  if valid_601230 != nil:
    section.add "Manifest", valid_601230
  var valid_601231 = formData.getOrDefault("JobType")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = newJString("Import"))
  if valid_601231 != nil:
    section.add "JobType", valid_601231
  var valid_601232 = formData.getOrDefault("JobId")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "JobId", valid_601232
  var valid_601233 = formData.getOrDefault("ValidateOnly")
  valid_601233 = validateParameter(valid_601233, JBool, required = true, default = nil)
  if valid_601233 != nil:
    section.add "ValidateOnly", valid_601233
  var valid_601234 = formData.getOrDefault("APIVersion")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "APIVersion", valid_601234
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_PostUpdateJob_601219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_PostUpdateJob_601219; SignatureMethod: string;
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
  var query_601237 = newJObject()
  var formData_601238 = newJObject()
  add(query_601237, "SignatureMethod", newJString(SignatureMethod))
  add(query_601237, "Signature", newJString(Signature))
  add(formData_601238, "Manifest", newJString(Manifest))
  add(formData_601238, "JobType", newJString(JobType))
  add(query_601237, "Action", newJString(Action))
  add(query_601237, "Timestamp", newJString(Timestamp))
  add(formData_601238, "JobId", newJString(JobId))
  add(query_601237, "Operation", newJString(Operation))
  add(query_601237, "SignatureVersion", newJString(SignatureVersion))
  add(query_601237, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601237, "Version", newJString(Version))
  add(formData_601238, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_601238, "APIVersion", newJString(APIVersion))
  result = call_601236.call(nil, query_601237, nil, formData_601238, nil)

var postUpdateJob* = Call_PostUpdateJob_601219(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_601220, base: "/", url: url_PostUpdateJob_601221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_601200 = ref object of OpenApiRestCall_600410
proc url_GetUpdateJob_601202(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateJob_601201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601203 = query.getOrDefault("SignatureMethod")
  valid_601203 = validateParameter(valid_601203, JString, required = true,
                                 default = nil)
  if valid_601203 != nil:
    section.add "SignatureMethod", valid_601203
  var valid_601204 = query.getOrDefault("Manifest")
  valid_601204 = validateParameter(valid_601204, JString, required = true,
                                 default = nil)
  if valid_601204 != nil:
    section.add "Manifest", valid_601204
  var valid_601205 = query.getOrDefault("JobId")
  valid_601205 = validateParameter(valid_601205, JString, required = true,
                                 default = nil)
  if valid_601205 != nil:
    section.add "JobId", valid_601205
  var valid_601206 = query.getOrDefault("APIVersion")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "APIVersion", valid_601206
  var valid_601207 = query.getOrDefault("Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = nil)
  if valid_601207 != nil:
    section.add "Signature", valid_601207
  var valid_601208 = query.getOrDefault("Action")
  valid_601208 = validateParameter(valid_601208, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601208 != nil:
    section.add "Action", valid_601208
  var valid_601209 = query.getOrDefault("JobType")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = newJString("Import"))
  if valid_601209 != nil:
    section.add "JobType", valid_601209
  var valid_601210 = query.getOrDefault("ValidateOnly")
  valid_601210 = validateParameter(valid_601210, JBool, required = true, default = nil)
  if valid_601210 != nil:
    section.add "ValidateOnly", valid_601210
  var valid_601211 = query.getOrDefault("Timestamp")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = nil)
  if valid_601211 != nil:
    section.add "Timestamp", valid_601211
  var valid_601212 = query.getOrDefault("Operation")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_601212 != nil:
    section.add "Operation", valid_601212
  var valid_601213 = query.getOrDefault("SignatureVersion")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "SignatureVersion", valid_601213
  var valid_601214 = query.getOrDefault("AWSAccessKeyId")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "AWSAccessKeyId", valid_601214
  var valid_601215 = query.getOrDefault("Version")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601215 != nil:
    section.add "Version", valid_601215
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_GetUpdateJob_601200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"))
  result = hook(call_601216, url, valid)

proc call*(call_601217: Call_GetUpdateJob_601200; SignatureMethod: string;
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
  var query_601218 = newJObject()
  add(query_601218, "SignatureMethod", newJString(SignatureMethod))
  add(query_601218, "Manifest", newJString(Manifest))
  add(query_601218, "JobId", newJString(JobId))
  add(query_601218, "APIVersion", newJString(APIVersion))
  add(query_601218, "Signature", newJString(Signature))
  add(query_601218, "Action", newJString(Action))
  add(query_601218, "JobType", newJString(JobType))
  add(query_601218, "ValidateOnly", newJBool(ValidateOnly))
  add(query_601218, "Timestamp", newJString(Timestamp))
  add(query_601218, "Operation", newJString(Operation))
  add(query_601218, "SignatureVersion", newJString(SignatureVersion))
  add(query_601218, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601218, "Version", newJString(Version))
  result = call_601217.call(nil, query_601218, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_601200(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_601201, base: "/", url: url_GetUpdateJob_601202,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
