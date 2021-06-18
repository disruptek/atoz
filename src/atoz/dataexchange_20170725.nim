
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Data Exchange
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Data Exchange is a service that makes it easy for AWS customers to exchange data in the cloud. You can use the AWS Data Exchange APIs to create, update, manage, and access file-based data set in the AWS Cloud.</p><p>As a subscriber, you can view and access the data sets that you have an entitlement to through a subscription. You can use the APIS to download or copy your entitled data sets to Amazon S3 for use across a variety of AWS analytics and machine learning services.</p><p>As a provider, you can create and manage your data sets that you would like to publish to a product. Being able to package and provide your data sets into products requires a few steps to determine eligibility. For more information, visit the AWS Data Exchange User Guide.</p><p>A data set is a collection of data that can be changed or updated over time. Data sets can be updated using revisions, which represent a new version or incremental change to a data set.  A revision contains one or more assets. An asset in AWS Data Exchange is a piece of data that can be stored as an Amazon S3 object. The asset can be a structured data file, an image file, or some other data file. Jobs are asynchronous import or export operations used to create or copy assets.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dataexchange/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Https: {"ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com", "us-west-2": "dataexchange.us-west-2.amazonaws.com", "eu-west-2": "dataexchange.eu-west-2.amazonaws.com", "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com", "eu-central-1": "dataexchange.eu-central-1.amazonaws.com", "us-east-2": "dataexchange.us-east-2.amazonaws.com", "us-east-1": "dataexchange.us-east-1.amazonaws.com", "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "dataexchange.ap-south-1.amazonaws.com", "eu-north-1": "dataexchange.eu-north-1.amazonaws.com", "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com", "us-west-1": "dataexchange.us-west-1.amazonaws.com", "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com", "eu-west-3": "dataexchange.eu-west-3.amazonaws.com", "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn", "sa-east-1": "dataexchange.sa-east-1.amazonaws.com", "eu-west-1": "dataexchange.eu-west-1.amazonaws.com", "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com", "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
      "us-west-2": "dataexchange.us-west-2.amazonaws.com",
      "eu-west-2": "dataexchange.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
      "us-east-2": "dataexchange.us-east-2.amazonaws.com",
      "us-east-1": "dataexchange.us-east-1.amazonaws.com",
      "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dataexchange.ap-south-1.amazonaws.com",
      "eu-north-1": "dataexchange.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
      "us-west-1": "dataexchange.us-west-1.amazonaws.com",
      "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dataexchange.eu-west-3.amazonaws.com",
      "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
      "eu-west-1": "dataexchange.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dataexchange"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetJob_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetJob_402656296(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
                 (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_402656295(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a job.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
                                 ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_402656386 = path.getOrDefault("JobId")
  valid_402656386 = validateParameter(valid_402656386, JString, required = true,
                                      default = nil)
  if valid_402656386 != nil:
    section.add "JobId", valid_402656386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656407: Call_GetJob_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a job.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_GetJob_402656294; JobId: string): Recallable =
  ## getJob
  ## This operation returns information about a job.
  ##   JobId: string (required)
                                                    ##        : The unique identifier for a job.
  var path_402656457 = newJObject()
  add(path_402656457, "JobId", newJString(JobId))
  result = call_402656456.call(path_402656457, nil, nil, nil, nil)

var getJob* = Call_GetJob_402656294(name: "getJob", meth: HttpMethod.HttpGet,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs/{JobId}",
                                    validator: validate_GetJob_402656295,
                                    base: "/", makeUrl: url_GetJob_402656296,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_402656501 = ref object of OpenApiRestCall_402656044
proc url_StartJob_402656503(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
                 (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_402656502(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation starts a job.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
                                 ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_402656504 = path.getOrDefault("JobId")
  valid_402656504 = validateParameter(valid_402656504, JString, required = true,
                                      default = nil)
  if valid_402656504 != nil:
    section.add "JobId", valid_402656504
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656505 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Security-Token", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Signature")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Signature", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Algorithm", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Date")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Date", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Credential")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Credential", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656512: Call_StartJob_402656501; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation starts a job.
                                                                                         ## 
  let valid = call_402656512.validator(path, query, header, formData, body, _)
  let scheme = call_402656512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656512.makeUrl(scheme.get, call_402656512.host, call_402656512.base,
                                   call_402656512.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656512, uri, valid, _)

proc call*(call_402656513: Call_StartJob_402656501; JobId: string): Recallable =
  ## startJob
  ## This operation starts a job.
  ##   JobId: string (required)
                                 ##        : The unique identifier for a job.
  var path_402656514 = newJObject()
  add(path_402656514, "JobId", newJString(JobId))
  result = call_402656513.call(path_402656514, nil, nil, nil, nil)

var startJob* = Call_StartJob_402656501(name: "startJob",
                                        meth: HttpMethod.HttpPatch,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/v1/jobs/{JobId}",
                                        validator: validate_StartJob_402656502,
                                        base: "/", makeUrl: url_StartJob_402656503,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_402656487 = ref object of OpenApiRestCall_402656044
proc url_CancelJob_402656489(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
                 (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_402656488(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
                                 ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_402656490 = path.getOrDefault("JobId")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "JobId", valid_402656490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656498: Call_CancelJob_402656487; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_CancelJob_402656487; JobId: string): Recallable =
  ## cancelJob
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ##   
                                                                                                 ## JobId: string (required)
                                                                                                 ##        
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## unique 
                                                                                                 ## identifier 
                                                                                                 ## for 
                                                                                                 ## a 
                                                                                                 ## job.
  var path_402656500 = newJObject()
  add(path_402656500, "JobId", newJString(JobId))
  result = call_402656499.call(path_402656500, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_402656487(name: "cancelJob",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/jobs/{JobId}", validator: validate_CancelJob_402656488,
    base: "/", makeUrl: url_CancelJob_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_402656533 = ref object of OpenApiRestCall_402656044
proc url_CreateDataSet_402656535(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSet_402656534(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation creates a data set.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656536 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Security-Token", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Signature")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Signature", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Algorithm", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Date")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Date", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Credential")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Credential", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656544: Call_CreateDataSet_402656533; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation creates a data set.
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_CreateDataSet_402656533; body: JsonNode): Recallable =
  ## createDataSet
  ## This operation creates a data set.
  ##   body: JObject (required)
  var body_402656546 = newJObject()
  if body != nil:
    body_402656546 = body
  result = call_402656545.call(nil, nil, nil, nil, body_402656546)

var createDataSet* = Call_CreateDataSet_402656533(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_CreateDataSet_402656534,
    base: "/", makeUrl: url_CreateDataSet_402656535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_402656515 = ref object of OpenApiRestCall_402656044
proc url_ListDataSets_402656517(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataSets_402656516(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   origin: JString
                                  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   
                                                                                                                                                                         ## maxResults: JInt
                                                                                                                                                                         ##             
                                                                                                                                                                         ## : 
                                                                                                                                                                         ## The 
                                                                                                                                                                         ## maximum 
                                                                                                                                                                         ## number 
                                                                                                                                                                         ## of 
                                                                                                                                                                         ## results 
                                                                                                                                                                         ## returned 
                                                                                                                                                                         ## by 
                                                                                                                                                                         ## a 
                                                                                                                                                                         ## single 
                                                                                                                                                                         ## call.
  ##   
                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                 ##            
                                                                                                                                                                                 ## : 
                                                                                                                                                                                 ## The 
                                                                                                                                                                                 ## token 
                                                                                                                                                                                 ## value 
                                                                                                                                                                                 ## retrieved 
                                                                                                                                                                                 ## from 
                                                                                                                                                                                 ## a 
                                                                                                                                                                                 ## previous 
                                                                                                                                                                                 ## call 
                                                                                                                                                                                 ## to 
                                                                                                                                                                                 ## access 
                                                                                                                                                                                 ## the 
                                                                                                                                                                                 ## next 
                                                                                                                                                                                 ## page 
                                                                                                                                                                                 ## of 
                                                                                                                                                                                 ## results.
  ##   
                                                                                                                                                                                            ## MaxResults: JString
                                                                                                                                                                                            ##             
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                    ## NextToken: JString
                                                                                                                                                                                                    ##            
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                    ## token
  section = newJObject()
  var valid_402656518 = query.getOrDefault("origin")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "origin", valid_402656518
  var valid_402656519 = query.getOrDefault("maxResults")
  valid_402656519 = validateParameter(valid_402656519, JInt, required = false,
                                      default = nil)
  if valid_402656519 != nil:
    section.add "maxResults", valid_402656519
  var valid_402656520 = query.getOrDefault("nextToken")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "nextToken", valid_402656520
  var valid_402656521 = query.getOrDefault("MaxResults")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "MaxResults", valid_402656521
  var valid_402656522 = query.getOrDefault("NextToken")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "NextToken", valid_402656522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656530: Call_ListDataSets_402656515; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
                                                                                         ## 
  let valid = call_402656530.validator(path, query, header, formData, body, _)
  let scheme = call_402656530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656530.makeUrl(scheme.get, call_402656530.host, call_402656530.base,
                                   call_402656530.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656530, uri, valid, _)

proc call*(call_402656531: Call_ListDataSets_402656515; origin: string = "";
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listDataSets
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ##   
                                                                                                                                                                                                                        ## origin: string
                                                                                                                                                                                                                        ##         
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## A 
                                                                                                                                                                                                                        ## property 
                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                        ## defines 
                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                        ## data 
                                                                                                                                                                                                                        ## set 
                                                                                                                                                                                                                        ## as 
                                                                                                                                                                                                                        ## OWNED 
                                                                                                                                                                                                                        ## by 
                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                        ## account 
                                                                                                                                                                                                                        ## (for 
                                                                                                                                                                                                                        ## providers) 
                                                                                                                                                                                                                        ## or 
                                                                                                                                                                                                                        ## ENTITLED 
                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                        ## account 
                                                                                                                                                                                                                        ## (for 
                                                                                                                                                                                                                        ## subscribers).
  ##   
                                                                                                                                                                                                                                        ## maxResults: int
                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                        ## maximum 
                                                                                                                                                                                                                                        ## number 
                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                        ## results 
                                                                                                                                                                                                                                        ## returned 
                                                                                                                                                                                                                                        ## by 
                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                        ## single 
                                                                                                                                                                                                                                        ## call.
  ##   
                                                                                                                                                                                                                                                ## nextToken: string
                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                                                ## retrieved 
                                                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                ## previous 
                                                                                                                                                                                                                                                ## call 
                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                ## access 
                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                                ## page 
                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                ## results.
  ##   
                                                                                                                                                                                                                                                           ## MaxResults: string
                                                                                                                                                                                                                                                           ##             
                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                                                           ## limit
  ##   
                                                                                                                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                   ## token
  var query_402656532 = newJObject()
  add(query_402656532, "origin", newJString(origin))
  add(query_402656532, "maxResults", newJInt(maxResults))
  add(query_402656532, "nextToken", newJString(nextToken))
  add(query_402656532, "MaxResults", newJString(MaxResults))
  add(query_402656532, "NextToken", newJString(NextToken))
  result = call_402656531.call(nil, query_402656532, nil, nil, nil)

var listDataSets* = Call_ListDataSets_402656515(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_ListDataSets_402656516,
    base: "/", makeUrl: url_ListDataSets_402656517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_402656566 = ref object of OpenApiRestCall_402656044
proc url_CreateJob_402656568(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_402656567(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation creates a job.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656569 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Security-Token", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Signature")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Signature", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Algorithm", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Date")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Date", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Credential")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Credential", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656577: Call_CreateJob_402656566; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation creates a job.
                                                                                         ## 
  let valid = call_402656577.validator(path, query, header, formData, body, _)
  let scheme = call_402656577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656577.makeUrl(scheme.get, call_402656577.host, call_402656577.base,
                                   call_402656577.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656577, uri, valid, _)

proc call*(call_402656578: Call_CreateJob_402656566; body: JsonNode): Recallable =
  ## createJob
  ## This operation creates a job.
  ##   body: JObject (required)
  var body_402656579 = newJObject()
  if body != nil:
    body_402656579 = body
  result = call_402656578.call(nil, nil, nil, nil, body_402656579)

var createJob* = Call_CreateJob_402656566(name: "createJob",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/jobs", validator: validate_CreateJob_402656567, base: "/",
    makeUrl: url_CreateJob_402656568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_402656547 = ref object of OpenApiRestCall_402656044
proc url_ListJobs_402656549(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_402656548(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results returned by a single call.
  ##   
                                                                                                           ## nextToken: JString
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## token 
                                                                                                           ## value 
                                                                                                           ## retrieved 
                                                                                                           ## from 
                                                                                                           ## a 
                                                                                                           ## previous 
                                                                                                           ## call 
                                                                                                           ## to 
                                                                                                           ## access 
                                                                                                           ## the 
                                                                                                           ## next 
                                                                                                           ## page 
                                                                                                           ## of 
                                                                                                           ## results.
  ##   
                                                                                                                      ## MaxResults: JString
                                                                                                                      ##             
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## limit
  ##   
                                                                                                                              ## NextToken: JString
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  ##   
                                                                                                                                      ## dataSetId: JString
                                                                                                                                      ##            
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## unique 
                                                                                                                                      ## identifier 
                                                                                                                                      ## for 
                                                                                                                                      ## a 
                                                                                                                                      ## data 
                                                                                                                                      ## set.
  ##   
                                                                                                                                             ## revisionId: JString
                                                                                                                                             ##             
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## unique 
                                                                                                                                             ## identifier 
                                                                                                                                             ## for 
                                                                                                                                             ## a 
                                                                                                                                             ## revision.
  section = newJObject()
  var valid_402656550 = query.getOrDefault("maxResults")
  valid_402656550 = validateParameter(valid_402656550, JInt, required = false,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "maxResults", valid_402656550
  var valid_402656551 = query.getOrDefault("nextToken")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "nextToken", valid_402656551
  var valid_402656552 = query.getOrDefault("MaxResults")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "MaxResults", valid_402656552
  var valid_402656553 = query.getOrDefault("NextToken")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "NextToken", valid_402656553
  var valid_402656554 = query.getOrDefault("dataSetId")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "dataSetId", valid_402656554
  var valid_402656555 = query.getOrDefault("revisionId")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "revisionId", valid_402656555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656556 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Security-Token", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Signature")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Signature", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Algorithm", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Date")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Date", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Credential")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Credential", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656563: Call_ListJobs_402656547; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
                                                                                         ## 
  let valid = call_402656563.validator(path, query, header, formData, body, _)
  let scheme = call_402656563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656563.makeUrl(scheme.get, call_402656563.host, call_402656563.base,
                                   call_402656563.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656563, uri, valid, _)

proc call*(call_402656564: Call_ListJobs_402656547; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; dataSetId: string = "";
           revisionId: string = ""): Recallable =
  ## listJobs
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ##   
                                                                            ## maxResults: int
                                                                            ##             
                                                                            ## : 
                                                                            ## The 
                                                                            ## maximum 
                                                                            ## number 
                                                                            ## of 
                                                                            ## results 
                                                                            ## returned 
                                                                            ## by 
                                                                            ## a 
                                                                            ## single 
                                                                            ## call.
  ##   
                                                                                    ## nextToken: string
                                                                                    ##            
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## token 
                                                                                    ## value 
                                                                                    ## retrieved 
                                                                                    ## from 
                                                                                    ## a 
                                                                                    ## previous 
                                                                                    ## call 
                                                                                    ## to 
                                                                                    ## access 
                                                                                    ## the 
                                                                                    ## next 
                                                                                    ## page 
                                                                                    ## of 
                                                                                    ## results.
  ##   
                                                                                               ## MaxResults: string
                                                                                               ##             
                                                                                               ## : 
                                                                                               ## Pagination 
                                                                                               ## limit
  ##   
                                                                                                       ## NextToken: string
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## Pagination 
                                                                                                       ## token
  ##   
                                                                                                               ## dataSetId: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## unique 
                                                                                                               ## identifier 
                                                                                                               ## for 
                                                                                                               ## a 
                                                                                                               ## data 
                                                                                                               ## set.
  ##   
                                                                                                                      ## revisionId: string
                                                                                                                      ##             
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## unique 
                                                                                                                      ## identifier 
                                                                                                                      ## for 
                                                                                                                      ## a 
                                                                                                                      ## revision.
  var query_402656565 = newJObject()
  add(query_402656565, "maxResults", newJInt(maxResults))
  add(query_402656565, "nextToken", newJString(nextToken))
  add(query_402656565, "MaxResults", newJString(MaxResults))
  add(query_402656565, "NextToken", newJString(NextToken))
  add(query_402656565, "dataSetId", newJString(dataSetId))
  add(query_402656565, "revisionId", newJString(revisionId))
  result = call_402656564.call(nil, query_402656565, nil, nil, nil)

var listJobs* = Call_ListJobs_402656547(name: "listJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/v1/jobs",
                                        validator: validate_ListJobs_402656548,
                                        base: "/", makeUrl: url_ListJobs_402656549,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRevision_402656599 = ref object of OpenApiRestCall_402656044
proc url_CreateRevision_402656601(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRevision_402656600(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation creates a revision for a data set.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656602 = path.getOrDefault("DataSetId")
  valid_402656602 = validateParameter(valid_402656602, JString, required = true,
                                      default = nil)
  if valid_402656602 != nil:
    section.add "DataSetId", valid_402656602
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656603 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Security-Token", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Signature")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Signature", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Algorithm", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Date")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Date", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Credential")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Credential", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656611: Call_CreateRevision_402656599; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation creates a revision for a data set.
                                                                                         ## 
  let valid = call_402656611.validator(path, query, header, formData, body, _)
  let scheme = call_402656611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656611.makeUrl(scheme.get, call_402656611.host, call_402656611.base,
                                   call_402656611.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656611, uri, valid, _)

proc call*(call_402656612: Call_CreateRevision_402656599; body: JsonNode;
           DataSetId: string): Recallable =
  ## createRevision
  ## This operation creates a revision for a data set.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
                               ##            : The unique identifier for a data set.
  var path_402656613 = newJObject()
  var body_402656614 = newJObject()
  if body != nil:
    body_402656614 = body
  add(path_402656613, "DataSetId", newJString(DataSetId))
  result = call_402656612.call(path_402656613, nil, nil, nil, body_402656614)

var createRevision* = Call_CreateRevision_402656599(name: "createRevision",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_CreateRevision_402656600, base: "/",
    makeUrl: url_CreateRevision_402656601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSetRevisions_402656580 = ref object of OpenApiRestCall_402656044
proc url_ListDataSetRevisions_402656582(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSetRevisions_402656581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656583 = path.getOrDefault("DataSetId")
  valid_402656583 = validateParameter(valid_402656583, JString, required = true,
                                      default = nil)
  if valid_402656583 != nil:
    section.add "DataSetId", valid_402656583
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results returned by a single call.
  ##   
                                                                                                           ## nextToken: JString
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## token 
                                                                                                           ## value 
                                                                                                           ## retrieved 
                                                                                                           ## from 
                                                                                                           ## a 
                                                                                                           ## previous 
                                                                                                           ## call 
                                                                                                           ## to 
                                                                                                           ## access 
                                                                                                           ## the 
                                                                                                           ## next 
                                                                                                           ## page 
                                                                                                           ## of 
                                                                                                           ## results.
  ##   
                                                                                                                      ## MaxResults: JString
                                                                                                                      ##             
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## limit
  ##   
                                                                                                                              ## NextToken: JString
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  section = newJObject()
  var valid_402656584 = query.getOrDefault("maxResults")
  valid_402656584 = validateParameter(valid_402656584, JInt, required = false,
                                      default = nil)
  if valid_402656584 != nil:
    section.add "maxResults", valid_402656584
  var valid_402656585 = query.getOrDefault("nextToken")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "nextToken", valid_402656585
  var valid_402656586 = query.getOrDefault("MaxResults")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "MaxResults", valid_402656586
  var valid_402656587 = query.getOrDefault("NextToken")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "NextToken", valid_402656587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656588 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Security-Token", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Signature")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Signature", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Algorithm", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Date")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Date", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Credential")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Credential", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656595: Call_ListDataSetRevisions_402656580;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
                                                                                         ## 
  let valid = call_402656595.validator(path, query, header, formData, body, _)
  let scheme = call_402656595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656595.makeUrl(scheme.get, call_402656595.host, call_402656595.base,
                                   call_402656595.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656595, uri, valid, _)

proc call*(call_402656596: Call_ListDataSetRevisions_402656580;
           DataSetId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDataSetRevisions
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ##   
                                                                                         ## maxResults: int
                                                                                         ##             
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## maximum 
                                                                                         ## number 
                                                                                         ## of 
                                                                                         ## results 
                                                                                         ## returned 
                                                                                         ## by 
                                                                                         ## a 
                                                                                         ## single 
                                                                                         ## call.
  ##   
                                                                                                 ## nextToken: string
                                                                                                 ##            
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## token 
                                                                                                 ## value 
                                                                                                 ## retrieved 
                                                                                                 ## from 
                                                                                                 ## a 
                                                                                                 ## previous 
                                                                                                 ## call 
                                                                                                 ## to 
                                                                                                 ## access 
                                                                                                 ## the 
                                                                                                 ## next 
                                                                                                 ## page 
                                                                                                 ## of 
                                                                                                 ## results.
  ##   
                                                                                                            ## MaxResults: string
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## limit
  ##   
                                                                                                                    ## DataSetId: string (required)
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## unique 
                                                                                                                    ## identifier 
                                                                                                                    ## for 
                                                                                                                    ## a 
                                                                                                                    ## data 
                                                                                                                    ## set.
  ##   
                                                                                                                           ## NextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## token
  var path_402656597 = newJObject()
  var query_402656598 = newJObject()
  add(query_402656598, "maxResults", newJInt(maxResults))
  add(query_402656598, "nextToken", newJString(nextToken))
  add(query_402656598, "MaxResults", newJString(MaxResults))
  add(path_402656597, "DataSetId", newJString(DataSetId))
  add(query_402656598, "NextToken", newJString(NextToken))
  result = call_402656596.call(path_402656597, query_402656598, nil, nil, nil)

var listDataSetRevisions* = Call_ListDataSetRevisions_402656580(
    name: "listDataSetRevisions", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_ListDataSetRevisions_402656581, base: "/",
    makeUrl: url_ListDataSetRevisions_402656582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAsset_402656615 = ref object of OpenApiRestCall_402656044
proc url_GetAsset_402656617(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId"),
                 (kind: ConstantSegment, value: "/assets/"),
                 (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAsset_402656616(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about an asset.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  ##   
                                                                                                  ## AssetId: JString (required)
                                                                                                  ##          
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## unique 
                                                                                                  ## identifier 
                                                                                                  ## for 
                                                                                                  ## an 
                                                                                                  ## asset.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656618 = path.getOrDefault("DataSetId")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "DataSetId", valid_402656618
  var valid_402656619 = path.getOrDefault("RevisionId")
  valid_402656619 = validateParameter(valid_402656619, JString, required = true,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "RevisionId", valid_402656619
  var valid_402656620 = path.getOrDefault("AssetId")
  valid_402656620 = validateParameter(valid_402656620, JString, required = true,
                                      default = nil)
  if valid_402656620 != nil:
    section.add "AssetId", valid_402656620
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656621 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Security-Token", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Signature")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Signature", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Algorithm", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Date")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Date", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Credential")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Credential", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656628: Call_GetAsset_402656615; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about an asset.
                                                                                         ## 
  let valid = call_402656628.validator(path, query, header, formData, body, _)
  let scheme = call_402656628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656628.makeUrl(scheme.get, call_402656628.host, call_402656628.base,
                                   call_402656628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656628, uri, valid, _)

proc call*(call_402656629: Call_GetAsset_402656615; DataSetId: string;
           RevisionId: string; AssetId: string): Recallable =
  ## getAsset
  ## This operation returns information about an asset.
  ##   DataSetId: string (required)
                                                       ##            : The unique identifier for a data set.
  ##   
                                                                                                            ## RevisionId: string (required)
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## unique 
                                                                                                            ## identifier 
                                                                                                            ## for 
                                                                                                            ## a 
                                                                                                            ## revision.
  ##   
                                                                                                                        ## AssetId: string (required)
                                                                                                                        ##          
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## unique 
                                                                                                                        ## identifier 
                                                                                                                        ## for 
                                                                                                                        ## an 
                                                                                                                        ## asset.
  var path_402656630 = newJObject()
  add(path_402656630, "DataSetId", newJString(DataSetId))
  add(path_402656630, "RevisionId", newJString(RevisionId))
  add(path_402656630, "AssetId", newJString(AssetId))
  result = call_402656629.call(path_402656630, nil, nil, nil, nil)

var getAsset* = Call_GetAsset_402656615(name: "getAsset",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_GetAsset_402656616,
                                        base: "/", makeUrl: url_GetAsset_402656617,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAsset_402656647 = ref object of OpenApiRestCall_402656044
proc url_UpdateAsset_402656649(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId"),
                 (kind: ConstantSegment, value: "/assets/"),
                 (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAsset_402656648(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation updates an asset.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  ##   
                                                                                                  ## AssetId: JString (required)
                                                                                                  ##          
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## unique 
                                                                                                  ## identifier 
                                                                                                  ## for 
                                                                                                  ## an 
                                                                                                  ## asset.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656650 = path.getOrDefault("DataSetId")
  valid_402656650 = validateParameter(valid_402656650, JString, required = true,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "DataSetId", valid_402656650
  var valid_402656651 = path.getOrDefault("RevisionId")
  valid_402656651 = validateParameter(valid_402656651, JString, required = true,
                                      default = nil)
  if valid_402656651 != nil:
    section.add "RevisionId", valid_402656651
  var valid_402656652 = path.getOrDefault("AssetId")
  valid_402656652 = validateParameter(valid_402656652, JString, required = true,
                                      default = nil)
  if valid_402656652 != nil:
    section.add "AssetId", valid_402656652
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656653 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Security-Token", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Signature")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Signature", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Algorithm", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Date")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Date", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Credential")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Credential", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656661: Call_UpdateAsset_402656647; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation updates an asset.
                                                                                         ## 
  let valid = call_402656661.validator(path, query, header, formData, body, _)
  let scheme = call_402656661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656661.makeUrl(scheme.get, call_402656661.host, call_402656661.base,
                                   call_402656661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656661, uri, valid, _)

proc call*(call_402656662: Call_UpdateAsset_402656647; body: JsonNode;
           DataSetId: string; RevisionId: string; AssetId: string): Recallable =
  ## updateAsset
  ## This operation updates an asset.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
                               ##            : The unique identifier for a data set.
  ##   
                                                                                    ## RevisionId: string (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## unique 
                                                                                    ## identifier 
                                                                                    ## for 
                                                                                    ## a 
                                                                                    ## revision.
  ##   
                                                                                                ## AssetId: string (required)
                                                                                                ##          
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## unique 
                                                                                                ## identifier 
                                                                                                ## for 
                                                                                                ## an 
                                                                                                ## asset.
  var path_402656663 = newJObject()
  var body_402656664 = newJObject()
  if body != nil:
    body_402656664 = body
  add(path_402656663, "DataSetId", newJString(DataSetId))
  add(path_402656663, "RevisionId", newJString(RevisionId))
  add(path_402656663, "AssetId", newJString(AssetId))
  result = call_402656662.call(path_402656663, nil, nil, nil, body_402656664)

var updateAsset* = Call_UpdateAsset_402656647(name: "updateAsset",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
    validator: validate_UpdateAsset_402656648, base: "/",
    makeUrl: url_UpdateAsset_402656649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_402656631 = ref object of OpenApiRestCall_402656044
proc url_DeleteAsset_402656633(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId"),
                 (kind: ConstantSegment, value: "/assets/"),
                 (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_402656632(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation deletes an asset.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  ##   
                                                                                                  ## AssetId: JString (required)
                                                                                                  ##          
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## unique 
                                                                                                  ## identifier 
                                                                                                  ## for 
                                                                                                  ## an 
                                                                                                  ## asset.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656634 = path.getOrDefault("DataSetId")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "DataSetId", valid_402656634
  var valid_402656635 = path.getOrDefault("RevisionId")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "RevisionId", valid_402656635
  var valid_402656636 = path.getOrDefault("AssetId")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = nil)
  if valid_402656636 != nil:
    section.add "AssetId", valid_402656636
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656637 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Security-Token", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Signature")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Signature", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Algorithm", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Date")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Date", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Credential")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Credential", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656644: Call_DeleteAsset_402656631; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation deletes an asset.
                                                                                         ## 
  let valid = call_402656644.validator(path, query, header, formData, body, _)
  let scheme = call_402656644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656644.makeUrl(scheme.get, call_402656644.host, call_402656644.base,
                                   call_402656644.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656644, uri, valid, _)

proc call*(call_402656645: Call_DeleteAsset_402656631; DataSetId: string;
           RevisionId: string; AssetId: string): Recallable =
  ## deleteAsset
  ## This operation deletes an asset.
  ##   DataSetId: string (required)
                                     ##            : The unique identifier for a data set.
  ##   
                                                                                          ## RevisionId: string (required)
                                                                                          ##             
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## unique 
                                                                                          ## identifier 
                                                                                          ## for 
                                                                                          ## a 
                                                                                          ## revision.
  ##   
                                                                                                      ## AssetId: string (required)
                                                                                                      ##          
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## unique 
                                                                                                      ## identifier 
                                                                                                      ## for 
                                                                                                      ## an 
                                                                                                      ## asset.
  var path_402656646 = newJObject()
  add(path_402656646, "DataSetId", newJString(DataSetId))
  add(path_402656646, "RevisionId", newJString(RevisionId))
  add(path_402656646, "AssetId", newJString(AssetId))
  result = call_402656645.call(path_402656646, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_402656631(name: "deleteAsset",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
    validator: validate_DeleteAsset_402656632, base: "/",
    makeUrl: url_DeleteAsset_402656633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSet_402656665 = ref object of OpenApiRestCall_402656044
proc url_GetDataSet_402656667(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSet_402656666(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a data set.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656668 = path.getOrDefault("DataSetId")
  valid_402656668 = validateParameter(valid_402656668, JString, required = true,
                                      default = nil)
  if valid_402656668 != nil:
    section.add "DataSetId", valid_402656668
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656669 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Security-Token", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Signature")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Signature", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Algorithm", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Date")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Date", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Credential")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Credential", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656676: Call_GetDataSet_402656665; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a data set.
                                                                                         ## 
  let valid = call_402656676.validator(path, query, header, formData, body, _)
  let scheme = call_402656676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656676.makeUrl(scheme.get, call_402656676.host, call_402656676.base,
                                   call_402656676.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656676, uri, valid, _)

proc call*(call_402656677: Call_GetDataSet_402656665; DataSetId: string): Recallable =
  ## getDataSet
  ## This operation returns information about a data set.
  ##   DataSetId: string (required)
                                                         ##            : The unique identifier for a data set.
  var path_402656678 = newJObject()
  add(path_402656678, "DataSetId", newJString(DataSetId))
  result = call_402656677.call(path_402656678, nil, nil, nil, nil)

var getDataSet* = Call_GetDataSet_402656665(name: "getDataSet",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_GetDataSet_402656666,
    base: "/", makeUrl: url_GetDataSet_402656667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_402656693 = ref object of OpenApiRestCall_402656044
proc url_UpdateDataSet_402656695(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_402656694(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation updates a data set.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656696 = path.getOrDefault("DataSetId")
  valid_402656696 = validateParameter(valid_402656696, JString, required = true,
                                      default = nil)
  if valid_402656696 != nil:
    section.add "DataSetId", valid_402656696
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656697 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Security-Token", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Signature")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Signature", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Algorithm", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Date")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Date", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Credential")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Credential", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656705: Call_UpdateDataSet_402656693; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation updates a data set.
                                                                                         ## 
  let valid = call_402656705.validator(path, query, header, formData, body, _)
  let scheme = call_402656705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656705.makeUrl(scheme.get, call_402656705.host, call_402656705.base,
                                   call_402656705.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656705, uri, valid, _)

proc call*(call_402656706: Call_UpdateDataSet_402656693; body: JsonNode;
           DataSetId: string): Recallable =
  ## updateDataSet
  ## This operation updates a data set.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
                               ##            : The unique identifier for a data set.
  var path_402656707 = newJObject()
  var body_402656708 = newJObject()
  if body != nil:
    body_402656708 = body
  add(path_402656707, "DataSetId", newJString(DataSetId))
  result = call_402656706.call(path_402656707, nil, nil, nil, body_402656708)

var updateDataSet* = Call_UpdateDataSet_402656693(name: "updateDataSet",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_UpdateDataSet_402656694,
    base: "/", makeUrl: url_UpdateDataSet_402656695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_402656679 = ref object of OpenApiRestCall_402656044
proc url_DeleteDataSet_402656681(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_402656680(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation deletes a data set.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656682 = path.getOrDefault("DataSetId")
  valid_402656682 = validateParameter(valid_402656682, JString, required = true,
                                      default = nil)
  if valid_402656682 != nil:
    section.add "DataSetId", valid_402656682
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656683 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Security-Token", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Signature")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Signature", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Algorithm", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Date")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Date", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Credential")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Credential", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656690: Call_DeleteDataSet_402656679; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation deletes a data set.
                                                                                         ## 
  let valid = call_402656690.validator(path, query, header, formData, body, _)
  let scheme = call_402656690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656690.makeUrl(scheme.get, call_402656690.host, call_402656690.base,
                                   call_402656690.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656690, uri, valid, _)

proc call*(call_402656691: Call_DeleteDataSet_402656679; DataSetId: string): Recallable =
  ## deleteDataSet
  ## This operation deletes a data set.
  ##   DataSetId: string (required)
                                       ##            : The unique identifier for a data set.
  var path_402656692 = newJObject()
  add(path_402656692, "DataSetId", newJString(DataSetId))
  result = call_402656691.call(path_402656692, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_402656679(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_DeleteDataSet_402656680,
    base: "/", makeUrl: url_DeleteDataSet_402656681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_402656709 = ref object of OpenApiRestCall_402656044
proc url_GetRevision_402656711(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_402656710(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a revision.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656712 = path.getOrDefault("DataSetId")
  valid_402656712 = validateParameter(valid_402656712, JString, required = true,
                                      default = nil)
  if valid_402656712 != nil:
    section.add "DataSetId", valid_402656712
  var valid_402656713 = path.getOrDefault("RevisionId")
  valid_402656713 = validateParameter(valid_402656713, JString, required = true,
                                      default = nil)
  if valid_402656713 != nil:
    section.add "RevisionId", valid_402656713
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656714 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Security-Token", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Signature")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Signature", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Algorithm", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Date")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Date", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Credential")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Credential", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656721: Call_GetRevision_402656709; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a revision.
                                                                                         ## 
  let valid = call_402656721.validator(path, query, header, formData, body, _)
  let scheme = call_402656721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656721.makeUrl(scheme.get, call_402656721.host, call_402656721.base,
                                   call_402656721.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656721, uri, valid, _)

proc call*(call_402656722: Call_GetRevision_402656709; DataSetId: string;
           RevisionId: string): Recallable =
  ## getRevision
  ## This operation returns information about a revision.
  ##   DataSetId: string (required)
                                                         ##            : The unique identifier for a data set.
  ##   
                                                                                                              ## RevisionId: string (required)
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## unique 
                                                                                                              ## identifier 
                                                                                                              ## for 
                                                                                                              ## a 
                                                                                                              ## revision.
  var path_402656723 = newJObject()
  add(path_402656723, "DataSetId", newJString(DataSetId))
  add(path_402656723, "RevisionId", newJString(RevisionId))
  result = call_402656722.call(path_402656723, nil, nil, nil, nil)

var getRevision* = Call_GetRevision_402656709(name: "getRevision",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_GetRevision_402656710, base: "/",
    makeUrl: url_GetRevision_402656711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRevision_402656739 = ref object of OpenApiRestCall_402656044
proc url_UpdateRevision_402656741(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRevision_402656740(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation updates a revision.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656742 = path.getOrDefault("DataSetId")
  valid_402656742 = validateParameter(valid_402656742, JString, required = true,
                                      default = nil)
  if valid_402656742 != nil:
    section.add "DataSetId", valid_402656742
  var valid_402656743 = path.getOrDefault("RevisionId")
  valid_402656743 = validateParameter(valid_402656743, JString, required = true,
                                      default = nil)
  if valid_402656743 != nil:
    section.add "RevisionId", valid_402656743
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656744 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Security-Token", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Signature")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Signature", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Algorithm", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Date")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Date", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Credential")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Credential", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656752: Call_UpdateRevision_402656739; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation updates a revision.
                                                                                         ## 
  let valid = call_402656752.validator(path, query, header, formData, body, _)
  let scheme = call_402656752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656752.makeUrl(scheme.get, call_402656752.host, call_402656752.base,
                                   call_402656752.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656752, uri, valid, _)

proc call*(call_402656753: Call_UpdateRevision_402656739; body: JsonNode;
           DataSetId: string; RevisionId: string): Recallable =
  ## updateRevision
  ## This operation updates a revision.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
                               ##            : The unique identifier for a data set.
  ##   
                                                                                    ## RevisionId: string (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## unique 
                                                                                    ## identifier 
                                                                                    ## for 
                                                                                    ## a 
                                                                                    ## revision.
  var path_402656754 = newJObject()
  var body_402656755 = newJObject()
  if body != nil:
    body_402656755 = body
  add(path_402656754, "DataSetId", newJString(DataSetId))
  add(path_402656754, "RevisionId", newJString(RevisionId))
  result = call_402656753.call(path_402656754, nil, nil, nil, body_402656755)

var updateRevision* = Call_UpdateRevision_402656739(name: "updateRevision",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_UpdateRevision_402656740, base: "/",
    makeUrl: url_UpdateRevision_402656741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRevision_402656724 = ref object of OpenApiRestCall_402656044
proc url_DeleteRevision_402656726(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRevision_402656725(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation deletes a revision.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656727 = path.getOrDefault("DataSetId")
  valid_402656727 = validateParameter(valid_402656727, JString, required = true,
                                      default = nil)
  if valid_402656727 != nil:
    section.add "DataSetId", valid_402656727
  var valid_402656728 = path.getOrDefault("RevisionId")
  valid_402656728 = validateParameter(valid_402656728, JString, required = true,
                                      default = nil)
  if valid_402656728 != nil:
    section.add "RevisionId", valid_402656728
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656729 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Security-Token", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Signature")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Signature", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Algorithm", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Date")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Date", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Credential")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Credential", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656736: Call_DeleteRevision_402656724; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation deletes a revision.
                                                                                         ## 
  let valid = call_402656736.validator(path, query, header, formData, body, _)
  let scheme = call_402656736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656736.makeUrl(scheme.get, call_402656736.host, call_402656736.base,
                                   call_402656736.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656736, uri, valid, _)

proc call*(call_402656737: Call_DeleteRevision_402656724; DataSetId: string;
           RevisionId: string): Recallable =
  ## deleteRevision
  ## This operation deletes a revision.
  ##   DataSetId: string (required)
                                       ##            : The unique identifier for a data set.
  ##   
                                                                                            ## RevisionId: string (required)
                                                                                            ##             
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## unique 
                                                                                            ## identifier 
                                                                                            ## for 
                                                                                            ## a 
                                                                                            ## revision.
  var path_402656738 = newJObject()
  add(path_402656738, "DataSetId", newJString(DataSetId))
  add(path_402656738, "RevisionId", newJString(RevisionId))
  result = call_402656737.call(path_402656738, nil, nil, nil, nil)

var deleteRevision* = Call_DeleteRevision_402656724(name: "deleteRevision",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_DeleteRevision_402656725, base: "/",
    makeUrl: url_DeleteRevision_402656726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRevisionAssets_402656756 = ref object of OpenApiRestCall_402656044
proc url_ListRevisionAssets_402656758(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
                 (kind: VariableSegment, value: "DataSetId"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "RevisionId"),
                 (kind: ConstantSegment, value: "/assets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRevisionAssets_402656757(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
                                 ##            : The unique identifier for a data set.
  ##   
                                                                                      ## RevisionId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## identifier 
                                                                                      ## for 
                                                                                      ## a 
                                                                                      ## revision.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DataSetId` field"
  var valid_402656759 = path.getOrDefault("DataSetId")
  valid_402656759 = validateParameter(valid_402656759, JString, required = true,
                                      default = nil)
  if valid_402656759 != nil:
    section.add "DataSetId", valid_402656759
  var valid_402656760 = path.getOrDefault("RevisionId")
  valid_402656760 = validateParameter(valid_402656760, JString, required = true,
                                      default = nil)
  if valid_402656760 != nil:
    section.add "RevisionId", valid_402656760
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results returned by a single call.
  ##   
                                                                                                           ## nextToken: JString
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## token 
                                                                                                           ## value 
                                                                                                           ## retrieved 
                                                                                                           ## from 
                                                                                                           ## a 
                                                                                                           ## previous 
                                                                                                           ## call 
                                                                                                           ## to 
                                                                                                           ## access 
                                                                                                           ## the 
                                                                                                           ## next 
                                                                                                           ## page 
                                                                                                           ## of 
                                                                                                           ## results.
  ##   
                                                                                                                      ## MaxResults: JString
                                                                                                                      ##             
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## limit
  ##   
                                                                                                                              ## NextToken: JString
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  section = newJObject()
  var valid_402656761 = query.getOrDefault("maxResults")
  valid_402656761 = validateParameter(valid_402656761, JInt, required = false,
                                      default = nil)
  if valid_402656761 != nil:
    section.add "maxResults", valid_402656761
  var valid_402656762 = query.getOrDefault("nextToken")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "nextToken", valid_402656762
  var valid_402656763 = query.getOrDefault("MaxResults")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "MaxResults", valid_402656763
  var valid_402656764 = query.getOrDefault("NextToken")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "NextToken", valid_402656764
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656772: Call_ListRevisionAssets_402656756;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
                                                                                         ## 
  let valid = call_402656772.validator(path, query, header, formData, body, _)
  let scheme = call_402656772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656772.makeUrl(scheme.get, call_402656772.host, call_402656772.base,
                                   call_402656772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656772, uri, valid, _)

proc call*(call_402656773: Call_ListRevisionAssets_402656756; DataSetId: string;
           RevisionId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRevisionAssets
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ##   
                                                                                        ## maxResults: int
                                                                                        ##             
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## maximum 
                                                                                        ## number 
                                                                                        ## of 
                                                                                        ## results 
                                                                                        ## returned 
                                                                                        ## by 
                                                                                        ## a 
                                                                                        ## single 
                                                                                        ## call.
  ##   
                                                                                                ## nextToken: string
                                                                                                ##            
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## token 
                                                                                                ## value 
                                                                                                ## retrieved 
                                                                                                ## from 
                                                                                                ## a 
                                                                                                ## previous 
                                                                                                ## call 
                                                                                                ## to 
                                                                                                ## access 
                                                                                                ## the 
                                                                                                ## next 
                                                                                                ## page 
                                                                                                ## of 
                                                                                                ## results.
  ##   
                                                                                                           ## MaxResults: string
                                                                                                           ##             
                                                                                                           ## : 
                                                                                                           ## Pagination 
                                                                                                           ## limit
  ##   
                                                                                                                   ## DataSetId: string (required)
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## unique 
                                                                                                                   ## identifier 
                                                                                                                   ## for 
                                                                                                                   ## a 
                                                                                                                   ## data 
                                                                                                                   ## set.
  ##   
                                                                                                                          ## NextToken: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## token
  ##   
                                                                                                                                  ## RevisionId: string (required)
                                                                                                                                  ##             
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## unique 
                                                                                                                                  ## identifier 
                                                                                                                                  ## for 
                                                                                                                                  ## a 
                                                                                                                                  ## revision.
  var path_402656774 = newJObject()
  var query_402656775 = newJObject()
  add(query_402656775, "maxResults", newJInt(maxResults))
  add(query_402656775, "nextToken", newJString(nextToken))
  add(query_402656775, "MaxResults", newJString(MaxResults))
  add(path_402656774, "DataSetId", newJString(DataSetId))
  add(query_402656775, "NextToken", newJString(NextToken))
  add(path_402656774, "RevisionId", newJString(RevisionId))
  result = call_402656773.call(path_402656774, query_402656775, nil, nil, nil)

var listRevisionAssets* = Call_ListRevisionAssets_402656756(
    name: "listRevisionAssets", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets",
    validator: validate_ListRevisionAssets_402656757, base: "/",
    makeUrl: url_ListRevisionAssets_402656758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656790 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656792(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656791(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation tags a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656793 = path.getOrDefault("resource-arn")
  valid_402656793 = validateParameter(valid_402656793, JString, required = true,
                                      default = nil)
  if valid_402656793 != nil:
    section.add "resource-arn", valid_402656793
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656794 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Security-Token", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Signature")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Signature", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Algorithm", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Date")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Date", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Credential")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Credential", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656802: Call_TagResource_402656790; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation tags a resource.
                                                                                         ## 
  let valid = call_402656802.validator(path, query, header, formData, body, _)
  let scheme = call_402656802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656802.makeUrl(scheme.get, call_402656802.host, call_402656802.base,
                                   call_402656802.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656802, uri, valid, _)

proc call*(call_402656803: Call_TagResource_402656790; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## This operation tags a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_402656804 = newJObject()
  var body_402656805 = newJObject()
  if body != nil:
    body_402656805 = body
  add(path_402656804, "resource-arn", newJString(resourceArn))
  result = call_402656803.call(path_402656804, nil, nil, nil, body_402656805)

var tagResource* = Call_TagResource_402656790(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_402656791,
    base: "/", makeUrl: url_TagResource_402656792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656776 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656778(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656777(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists the tags on the resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656779 = path.getOrDefault("resource-arn")
  valid_402656779 = validateParameter(valid_402656779, JString, required = true,
                                      default = nil)
  if valid_402656779 != nil:
    section.add "resource-arn", valid_402656779
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656780 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Security-Token", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Signature")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Signature", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Algorithm", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Date")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Date", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Credential")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Credential", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656787: Call_ListTagsForResource_402656776;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists the tags on the resource.
                                                                                         ## 
  let valid = call_402656787.validator(path, query, header, formData, body, _)
  let scheme = call_402656787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656787.makeUrl(scheme.get, call_402656787.host, call_402656787.base,
                                   call_402656787.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656787, uri, valid, _)

proc call*(call_402656788: Call_ListTagsForResource_402656776;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## This operation lists the tags on the resource.
  ##   resourceArn: string (required)
                                                   ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_402656789 = newJObject()
  add(path_402656789, "resource-arn", newJString(resourceArn))
  result = call_402656788.call(path_402656789, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656776(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_402656777, base: "/",
    makeUrl: url_ListTagsForResource_402656778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656806 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656808(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656807(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation removes one or more tags from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656809 = path.getOrDefault("resource-arn")
  valid_402656809 = validateParameter(valid_402656809, JString, required = true,
                                      default = nil)
  if valid_402656809 != nil:
    section.add "resource-arn", valid_402656809
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The key tags.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656810 = query.getOrDefault("tagKeys")
  valid_402656810 = validateParameter(valid_402656810, JArray, required = true,
                                      default = nil)
  if valid_402656810 != nil:
    section.add "tagKeys", valid_402656810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656811 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Security-Token", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Signature")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Signature", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Algorithm", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Date")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Date", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Credential")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Credential", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656818: Call_UntagResource_402656806; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation removes one or more tags from a resource.
                                                                                         ## 
  let valid = call_402656818.validator(path, query, header, formData, body, _)
  let scheme = call_402656818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656818.makeUrl(scheme.get, call_402656818.host, call_402656818.base,
                                   call_402656818.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656818, uri, valid, _)

proc call*(call_402656819: Call_UntagResource_402656806; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## This operation removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
                                                             ##          : The key tags.
  ##   
                                                                                        ## resourceArn: string (required)
                                                                                        ##              
                                                                                        ## : 
                                                                                        ## An 
                                                                                        ## Amazon 
                                                                                        ## Resource 
                                                                                        ## Name 
                                                                                        ## (ARN) 
                                                                                        ## that 
                                                                                        ## uniquely 
                                                                                        ## identifies 
                                                                                        ## an 
                                                                                        ## AWS 
                                                                                        ## resource.
  var path_402656820 = newJObject()
  var query_402656821 = newJObject()
  if tagKeys != nil:
    query_402656821.add "tagKeys", tagKeys
  add(path_402656820, "resource-arn", newJString(resourceArn))
  result = call_402656819.call(path_402656820, query_402656821, nil, nil, nil)

var untagResource* = Call_UntagResource_402656806(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_402656807,
    base: "/", makeUrl: url_UntagResource_402656808,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}