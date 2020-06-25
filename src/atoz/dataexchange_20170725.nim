
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  Scheme {.pure.} = enum
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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dataexchange.us-west-2.amazonaws.com",
                           "eu-west-2": "dataexchange.eu-west-2.amazonaws.com", "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com", "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
                           "us-east-2": "dataexchange.us-east-2.amazonaws.com",
                           "us-east-1": "dataexchange.us-east-1.amazonaws.com", "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "dataexchange.ap-south-1.amazonaws.com", "eu-north-1": "dataexchange.eu-north-1.amazonaws.com", "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dataexchange.us-west-1.amazonaws.com", "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dataexchange.eu-west-3.amazonaws.com", "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
                           "eu-west-1": "dataexchange.eu-west-1.amazonaws.com", "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com", "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_GetJob_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetJob_21625781(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetJob_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21625895 = path.getOrDefault("JobId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "JobId", valid_21625895
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625927: Call_GetJob_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a job.
  ## 
  let valid = call_21625927.validator(path, query, header, formData, body, _)
  let scheme = call_21625927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625927.makeUrl(scheme.get, call_21625927.host, call_21625927.base,
                               call_21625927.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625927, uri, valid, _)

proc call*(call_21625990: Call_GetJob_21625779; JobId: string): Recallable =
  ## getJob
  ## This operation returns information about a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_21625992 = newJObject()
  add(path_21625992, "JobId", newJString(JobId))
  result = call_21625990.call(path_21625992, nil, nil, nil, nil)

var getJob* = Call_GetJob_21625779(name: "getJob", meth: HttpMethod.HttpGet,
                                host: "dataexchange.amazonaws.com",
                                route: "/v1/jobs/{JobId}",
                                validator: validate_GetJob_21625780, base: "/",
                                makeUrl: url_GetJob_21625781,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_21626044 = ref object of OpenApiRestCall_21625435
proc url_StartJob_21626046(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_StartJob_21626045(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626047 = path.getOrDefault("JobId")
  valid_21626047 = validateParameter(valid_21626047, JString, required = true,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "JobId", valid_21626047
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626048 = header.getOrDefault("X-Amz-Date")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Date", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Security-Token", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626055: Call_StartJob_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation starts a job.
  ## 
  let valid = call_21626055.validator(path, query, header, formData, body, _)
  let scheme = call_21626055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626055.makeUrl(scheme.get, call_21626055.host, call_21626055.base,
                               call_21626055.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626055, uri, valid, _)

proc call*(call_21626056: Call_StartJob_21626044; JobId: string): Recallable =
  ## startJob
  ## This operation starts a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_21626057 = newJObject()
  add(path_21626057, "JobId", newJString(JobId))
  result = call_21626056.call(path_21626057, nil, nil, nil, nil)

var startJob* = Call_StartJob_21626044(name: "startJob", meth: HttpMethod.HttpPatch,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs/{JobId}",
                                    validator: validate_StartJob_21626045,
                                    base: "/", makeUrl: url_StartJob_21626046,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_21626030 = ref object of OpenApiRestCall_21625435
proc url_CancelJob_21626032(protocol: Scheme; host: string; base: string;
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

proc validate_CancelJob_21626031(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626033 = path.getOrDefault("JobId")
  valid_21626033 = validateParameter(valid_21626033, JString, required = true,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "JobId", valid_21626033
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Algorithm", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Signature")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Signature", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Credential")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Credential", valid_21626040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_CancelJob_21626030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_CancelJob_21626030; JobId: string): Recallable =
  ## cancelJob
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_21626043 = newJObject()
  add(path_21626043, "JobId", newJString(JobId))
  result = call_21626042.call(path_21626043, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_21626030(name: "cancelJob",
                                      meth: HttpMethod.HttpDelete,
                                      host: "dataexchange.amazonaws.com",
                                      route: "/v1/jobs/{JobId}",
                                      validator: validate_CancelJob_21626031,
                                      base: "/", makeUrl: url_CancelJob_21626032,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_21626077 = ref object of OpenApiRestCall_21625435
proc url_CreateDataSet_21626079(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSet_21626078(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation creates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626080 = header.getOrDefault("X-Amz-Date")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Date", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Security-Token", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Algorithm", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Signature")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Signature", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Credential")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Credential", valid_21626086
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

proc call*(call_21626088: Call_CreateDataSet_21626077; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation creates a data set.
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_CreateDataSet_21626077; body: JsonNode): Recallable =
  ## createDataSet
  ## This operation creates a data set.
  ##   body: JObject (required)
  var body_21626090 = newJObject()
  if body != nil:
    body_21626090 = body
  result = call_21626089.call(nil, nil, nil, nil, body_21626090)

var createDataSet* = Call_CreateDataSet_21626077(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_CreateDataSet_21626078, base: "/",
    makeUrl: url_CreateDataSet_21626079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_21626058 = ref object of OpenApiRestCall_21625435
proc url_ListDataSets_21626060(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataSets_21626059(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   origin: JString
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626061 = query.getOrDefault("origin")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "origin", valid_21626061
  var valid_21626062 = query.getOrDefault("NextToken")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "NextToken", valid_21626062
  var valid_21626063 = query.getOrDefault("maxResults")
  valid_21626063 = validateParameter(valid_21626063, JInt, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "maxResults", valid_21626063
  var valid_21626064 = query.getOrDefault("nextToken")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "nextToken", valid_21626064
  var valid_21626065 = query.getOrDefault("MaxResults")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "MaxResults", valid_21626065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626066 = header.getOrDefault("X-Amz-Date")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Date", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Security-Token", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Algorithm", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Signature")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Signature", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Credential")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Credential", valid_21626072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626073: Call_ListDataSets_21626058; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  let valid = call_21626073.validator(path, query, header, formData, body, _)
  let scheme = call_21626073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626073.makeUrl(scheme.get, call_21626073.host, call_21626073.base,
                               call_21626073.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626073, uri, valid, _)

proc call*(call_21626074: Call_ListDataSets_21626058; origin: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDataSets
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ##   origin: string
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626075 = newJObject()
  add(query_21626075, "origin", newJString(origin))
  add(query_21626075, "NextToken", newJString(NextToken))
  add(query_21626075, "maxResults", newJInt(maxResults))
  add(query_21626075, "nextToken", newJString(nextToken))
  add(query_21626075, "MaxResults", newJString(MaxResults))
  result = call_21626074.call(nil, query_21626075, nil, nil, nil)

var listDataSets* = Call_ListDataSets_21626058(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_ListDataSets_21626059, base: "/",
    makeUrl: url_ListDataSets_21626060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_21626110 = ref object of OpenApiRestCall_21625435
proc url_CreateJob_21626112(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_21626111(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626113 = header.getOrDefault("X-Amz-Date")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Date", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Security-Token", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Algorithm", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Signature")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Signature", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Credential")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Credential", valid_21626119
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

proc call*(call_21626121: Call_CreateJob_21626110; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation creates a job.
  ## 
  let valid = call_21626121.validator(path, query, header, formData, body, _)
  let scheme = call_21626121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626121.makeUrl(scheme.get, call_21626121.host, call_21626121.base,
                               call_21626121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626121, uri, valid, _)

proc call*(call_21626122: Call_CreateJob_21626110; body: JsonNode): Recallable =
  ## createJob
  ## This operation creates a job.
  ##   body: JObject (required)
  var body_21626123 = newJObject()
  if body != nil:
    body_21626123 = body
  result = call_21626122.call(nil, nil, nil, nil, body_21626123)

var createJob* = Call_CreateJob_21626110(name: "createJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "dataexchange.amazonaws.com",
                                      route: "/v1/jobs",
                                      validator: validate_CreateJob_21626111,
                                      base: "/", makeUrl: url_CreateJob_21626112,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_21626091 = ref object of OpenApiRestCall_21625435
proc url_ListJobs_21626093(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_21626092(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dataSetId: JString
  ##            : The unique identifier for a data set.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   revisionId: JString
  ##             : The unique identifier for a revision.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626094 = query.getOrDefault("dataSetId")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "dataSetId", valid_21626094
  var valid_21626095 = query.getOrDefault("NextToken")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "NextToken", valid_21626095
  var valid_21626096 = query.getOrDefault("maxResults")
  valid_21626096 = validateParameter(valid_21626096, JInt, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "maxResults", valid_21626096
  var valid_21626097 = query.getOrDefault("nextToken")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "nextToken", valid_21626097
  var valid_21626098 = query.getOrDefault("revisionId")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "revisionId", valid_21626098
  var valid_21626099 = query.getOrDefault("MaxResults")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "MaxResults", valid_21626099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Credential")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Credential", valid_21626106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_ListJobs_21626091; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_ListJobs_21626091; dataSetId: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          revisionId: string = ""; MaxResults: string = ""): Recallable =
  ## listJobs
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ##   dataSetId: string
  ##            : The unique identifier for a data set.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   revisionId: string
  ##             : The unique identifier for a revision.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626109 = newJObject()
  add(query_21626109, "dataSetId", newJString(dataSetId))
  add(query_21626109, "NextToken", newJString(NextToken))
  add(query_21626109, "maxResults", newJInt(maxResults))
  add(query_21626109, "nextToken", newJString(nextToken))
  add(query_21626109, "revisionId", newJString(revisionId))
  add(query_21626109, "MaxResults", newJString(MaxResults))
  result = call_21626108.call(nil, query_21626109, nil, nil, nil)

var listJobs* = Call_ListJobs_21626091(name: "listJobs", meth: HttpMethod.HttpGet,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs",
                                    validator: validate_ListJobs_21626092,
                                    base: "/", makeUrl: url_ListJobs_21626093,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRevision_21626143 = ref object of OpenApiRestCall_21625435
proc url_CreateRevision_21626145(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRevision_21626144(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_21626146 = path.getOrDefault("DataSetId")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "DataSetId", valid_21626146
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626147 = header.getOrDefault("X-Amz-Date")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Date", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Security-Token", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Algorithm", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Signature")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Signature", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Credential")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Credential", valid_21626153
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

proc call*(call_21626155: Call_CreateRevision_21626143; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation creates a revision for a data set.
  ## 
  let valid = call_21626155.validator(path, query, header, formData, body, _)
  let scheme = call_21626155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626155.makeUrl(scheme.get, call_21626155.host, call_21626155.base,
                               call_21626155.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626155, uri, valid, _)

proc call*(call_21626156: Call_CreateRevision_21626143; body: JsonNode;
          DataSetId: string): Recallable =
  ## createRevision
  ## This operation creates a revision for a data set.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626157 = newJObject()
  var body_21626158 = newJObject()
  if body != nil:
    body_21626158 = body
  add(path_21626157, "DataSetId", newJString(DataSetId))
  result = call_21626156.call(path_21626157, nil, nil, nil, body_21626158)

var createRevision* = Call_CreateRevision_21626143(name: "createRevision",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_CreateRevision_21626144, base: "/",
    makeUrl: url_CreateRevision_21626145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSetRevisions_21626124 = ref object of OpenApiRestCall_21625435
proc url_ListDataSetRevisions_21626126(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSetRevisions_21626125(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_21626127 = path.getOrDefault("DataSetId")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "DataSetId", valid_21626127
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626128 = query.getOrDefault("NextToken")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "NextToken", valid_21626128
  var valid_21626129 = query.getOrDefault("maxResults")
  valid_21626129 = validateParameter(valid_21626129, JInt, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "maxResults", valid_21626129
  var valid_21626130 = query.getOrDefault("nextToken")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "nextToken", valid_21626130
  var valid_21626131 = query.getOrDefault("MaxResults")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "MaxResults", valid_21626131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626132 = header.getOrDefault("X-Amz-Date")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Date", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Security-Token", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Algorithm", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Signature")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Signature", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Credential")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Credential", valid_21626138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626139: Call_ListDataSetRevisions_21626124; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  let valid = call_21626139.validator(path, query, header, formData, body, _)
  let scheme = call_21626139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626139.makeUrl(scheme.get, call_21626139.host, call_21626139.base,
                               call_21626139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626139, uri, valid, _)

proc call*(call_21626140: Call_ListDataSetRevisions_21626124; DataSetId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDataSetRevisions
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626141 = newJObject()
  var query_21626142 = newJObject()
  add(query_21626142, "NextToken", newJString(NextToken))
  add(query_21626142, "maxResults", newJInt(maxResults))
  add(query_21626142, "nextToken", newJString(nextToken))
  add(path_21626141, "DataSetId", newJString(DataSetId))
  add(query_21626142, "MaxResults", newJString(MaxResults))
  result = call_21626140.call(path_21626141, query_21626142, nil, nil, nil)

var listDataSetRevisions* = Call_ListDataSetRevisions_21626124(
    name: "listDataSetRevisions", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_ListDataSetRevisions_21626125, base: "/",
    makeUrl: url_ListDataSetRevisions_21626126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAsset_21626159 = ref object of OpenApiRestCall_21625435
proc url_GetAsset_21626161(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetAsset_21626160(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626162 = path.getOrDefault("RevisionId")
  valid_21626162 = validateParameter(valid_21626162, JString, required = true,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "RevisionId", valid_21626162
  var valid_21626163 = path.getOrDefault("AssetId")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "AssetId", valid_21626163
  var valid_21626164 = path.getOrDefault("DataSetId")
  valid_21626164 = validateParameter(valid_21626164, JString, required = true,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "DataSetId", valid_21626164
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626165 = header.getOrDefault("X-Amz-Date")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Date", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Security-Token", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Algorithm", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Signature")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Signature", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Credential")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Credential", valid_21626171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626172: Call_GetAsset_21626159; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about an asset.
  ## 
  let valid = call_21626172.validator(path, query, header, formData, body, _)
  let scheme = call_21626172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626172.makeUrl(scheme.get, call_21626172.host, call_21626172.base,
                               call_21626172.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626172, uri, valid, _)

proc call*(call_21626173: Call_GetAsset_21626159; RevisionId: string;
          AssetId: string; DataSetId: string): Recallable =
  ## getAsset
  ## This operation returns information about an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626174 = newJObject()
  add(path_21626174, "RevisionId", newJString(RevisionId))
  add(path_21626174, "AssetId", newJString(AssetId))
  add(path_21626174, "DataSetId", newJString(DataSetId))
  result = call_21626173.call(path_21626174, nil, nil, nil, nil)

var getAsset* = Call_GetAsset_21626159(name: "getAsset", meth: HttpMethod.HttpGet,
                                    host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                    validator: validate_GetAsset_21626160,
                                    base: "/", makeUrl: url_GetAsset_21626161,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAsset_21626191 = ref object of OpenApiRestCall_21625435
proc url_UpdateAsset_21626193(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAsset_21626192(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation updates an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626194 = path.getOrDefault("RevisionId")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "RevisionId", valid_21626194
  var valid_21626195 = path.getOrDefault("AssetId")
  valid_21626195 = validateParameter(valid_21626195, JString, required = true,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "AssetId", valid_21626195
  var valid_21626196 = path.getOrDefault("DataSetId")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "DataSetId", valid_21626196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Algorithm", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Signature")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Signature", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Credential")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Credential", valid_21626203
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

proc call*(call_21626205: Call_UpdateAsset_21626191; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation updates an asset.
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_UpdateAsset_21626191; RevisionId: string;
          AssetId: string; body: JsonNode; DataSetId: string): Recallable =
  ## updateAsset
  ## This operation updates an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626207 = newJObject()
  var body_21626208 = newJObject()
  add(path_21626207, "RevisionId", newJString(RevisionId))
  add(path_21626207, "AssetId", newJString(AssetId))
  if body != nil:
    body_21626208 = body
  add(path_21626207, "DataSetId", newJString(DataSetId))
  result = call_21626206.call(path_21626207, nil, nil, nil, body_21626208)

var updateAsset* = Call_UpdateAsset_21626191(name: "updateAsset",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
    validator: validate_UpdateAsset_21626192, base: "/", makeUrl: url_UpdateAsset_21626193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_21626175 = ref object of OpenApiRestCall_21625435
proc url_DeleteAsset_21626177(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAsset_21626176(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation deletes an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626178 = path.getOrDefault("RevisionId")
  valid_21626178 = validateParameter(valid_21626178, JString, required = true,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "RevisionId", valid_21626178
  var valid_21626179 = path.getOrDefault("AssetId")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "AssetId", valid_21626179
  var valid_21626180 = path.getOrDefault("DataSetId")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "DataSetId", valid_21626180
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626181 = header.getOrDefault("X-Amz-Date")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Date", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Security-Token", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Algorithm", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Signature")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Signature", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Credential")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Credential", valid_21626187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626188: Call_DeleteAsset_21626175; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation deletes an asset.
  ## 
  let valid = call_21626188.validator(path, query, header, formData, body, _)
  let scheme = call_21626188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626188.makeUrl(scheme.get, call_21626188.host, call_21626188.base,
                               call_21626188.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626188, uri, valid, _)

proc call*(call_21626189: Call_DeleteAsset_21626175; RevisionId: string;
          AssetId: string; DataSetId: string): Recallable =
  ## deleteAsset
  ## This operation deletes an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626190 = newJObject()
  add(path_21626190, "RevisionId", newJString(RevisionId))
  add(path_21626190, "AssetId", newJString(AssetId))
  add(path_21626190, "DataSetId", newJString(DataSetId))
  result = call_21626189.call(path_21626190, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_21626175(name: "deleteAsset",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
    validator: validate_DeleteAsset_21626176, base: "/", makeUrl: url_DeleteAsset_21626177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSet_21626209 = ref object of OpenApiRestCall_21625435
proc url_GetDataSet_21626211(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataSet_21626210(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_21626212 = path.getOrDefault("DataSetId")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "DataSetId", valid_21626212
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626213 = header.getOrDefault("X-Amz-Date")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Date", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Security-Token", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626220: Call_GetDataSet_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a data set.
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_GetDataSet_21626209; DataSetId: string): Recallable =
  ## getDataSet
  ## This operation returns information about a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626222 = newJObject()
  add(path_21626222, "DataSetId", newJString(DataSetId))
  result = call_21626221.call(path_21626222, nil, nil, nil, nil)

var getDataSet* = Call_GetDataSet_21626209(name: "getDataSet",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/v1/data-sets/{DataSetId}",
                                        validator: validate_GetDataSet_21626210,
                                        base: "/", makeUrl: url_GetDataSet_21626211,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_21626237 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataSet_21626239(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSet_21626238(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation updates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_21626240 = path.getOrDefault("DataSetId")
  valid_21626240 = validateParameter(valid_21626240, JString, required = true,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "DataSetId", valid_21626240
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626241 = header.getOrDefault("X-Amz-Date")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Date", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Security-Token", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Algorithm", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Signature")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Signature", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Credential")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Credential", valid_21626247
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

proc call*(call_21626249: Call_UpdateDataSet_21626237; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation updates a data set.
  ## 
  let valid = call_21626249.validator(path, query, header, formData, body, _)
  let scheme = call_21626249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626249.makeUrl(scheme.get, call_21626249.host, call_21626249.base,
                               call_21626249.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626249, uri, valid, _)

proc call*(call_21626250: Call_UpdateDataSet_21626237; body: JsonNode;
          DataSetId: string): Recallable =
  ## updateDataSet
  ## This operation updates a data set.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626251 = newJObject()
  var body_21626252 = newJObject()
  if body != nil:
    body_21626252 = body
  add(path_21626251, "DataSetId", newJString(DataSetId))
  result = call_21626250.call(path_21626251, nil, nil, nil, body_21626252)

var updateDataSet* = Call_UpdateDataSet_21626237(name: "updateDataSet",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_UpdateDataSet_21626238,
    base: "/", makeUrl: url_UpdateDataSet_21626239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_21626223 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataSet_21626225(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSet_21626224(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation deletes a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_21626226 = path.getOrDefault("DataSetId")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "DataSetId", valid_21626226
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Algorithm", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Signature")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Signature", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Credential")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Credential", valid_21626233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626234: Call_DeleteDataSet_21626223; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation deletes a data set.
  ## 
  let valid = call_21626234.validator(path, query, header, formData, body, _)
  let scheme = call_21626234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626234.makeUrl(scheme.get, call_21626234.host, call_21626234.base,
                               call_21626234.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626234, uri, valid, _)

proc call*(call_21626235: Call_DeleteDataSet_21626223; DataSetId: string): Recallable =
  ## deleteDataSet
  ## This operation deletes a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626236 = newJObject()
  add(path_21626236, "DataSetId", newJString(DataSetId))
  result = call_21626235.call(path_21626236, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_21626223(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_DeleteDataSet_21626224,
    base: "/", makeUrl: url_DeleteDataSet_21626225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_21626253 = ref object of OpenApiRestCall_21625435
proc url_GetRevision_21626255(protocol: Scheme; host: string; base: string;
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

proc validate_GetRevision_21626254(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626256 = path.getOrDefault("RevisionId")
  valid_21626256 = validateParameter(valid_21626256, JString, required = true,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "RevisionId", valid_21626256
  var valid_21626257 = path.getOrDefault("DataSetId")
  valid_21626257 = validateParameter(valid_21626257, JString, required = true,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "DataSetId", valid_21626257
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626258 = header.getOrDefault("X-Amz-Date")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Date", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Security-Token", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626265: Call_GetRevision_21626253; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a revision.
  ## 
  let valid = call_21626265.validator(path, query, header, formData, body, _)
  let scheme = call_21626265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626265.makeUrl(scheme.get, call_21626265.host, call_21626265.base,
                               call_21626265.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626265, uri, valid, _)

proc call*(call_21626266: Call_GetRevision_21626253; RevisionId: string;
          DataSetId: string): Recallable =
  ## getRevision
  ## This operation returns information about a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626267 = newJObject()
  add(path_21626267, "RevisionId", newJString(RevisionId))
  add(path_21626267, "DataSetId", newJString(DataSetId))
  result = call_21626266.call(path_21626267, nil, nil, nil, nil)

var getRevision* = Call_GetRevision_21626253(name: "getRevision",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_GetRevision_21626254, base: "/", makeUrl: url_GetRevision_21626255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRevision_21626283 = ref object of OpenApiRestCall_21625435
proc url_UpdateRevision_21626285(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRevision_21626284(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation updates a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626286 = path.getOrDefault("RevisionId")
  valid_21626286 = validateParameter(valid_21626286, JString, required = true,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "RevisionId", valid_21626286
  var valid_21626287 = path.getOrDefault("DataSetId")
  valid_21626287 = validateParameter(valid_21626287, JString, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "DataSetId", valid_21626287
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626288 = header.getOrDefault("X-Amz-Date")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Date", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Security-Token", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
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

proc call*(call_21626296: Call_UpdateRevision_21626283; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation updates a revision.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_UpdateRevision_21626283; RevisionId: string;
          body: JsonNode; DataSetId: string): Recallable =
  ## updateRevision
  ## This operation updates a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626298 = newJObject()
  var body_21626299 = newJObject()
  add(path_21626298, "RevisionId", newJString(RevisionId))
  if body != nil:
    body_21626299 = body
  add(path_21626298, "DataSetId", newJString(DataSetId))
  result = call_21626297.call(path_21626298, nil, nil, nil, body_21626299)

var updateRevision* = Call_UpdateRevision_21626283(name: "updateRevision",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_UpdateRevision_21626284, base: "/",
    makeUrl: url_UpdateRevision_21626285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRevision_21626268 = ref object of OpenApiRestCall_21625435
proc url_DeleteRevision_21626270(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRevision_21626269(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation deletes a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626271 = path.getOrDefault("RevisionId")
  valid_21626271 = validateParameter(valid_21626271, JString, required = true,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "RevisionId", valid_21626271
  var valid_21626272 = path.getOrDefault("DataSetId")
  valid_21626272 = validateParameter(valid_21626272, JString, required = true,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "DataSetId", valid_21626272
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626273 = header.getOrDefault("X-Amz-Date")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Date", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Security-Token", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626280: Call_DeleteRevision_21626268; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation deletes a revision.
  ## 
  let valid = call_21626280.validator(path, query, header, formData, body, _)
  let scheme = call_21626280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626280.makeUrl(scheme.get, call_21626280.host, call_21626280.base,
                               call_21626280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626280, uri, valid, _)

proc call*(call_21626281: Call_DeleteRevision_21626268; RevisionId: string;
          DataSetId: string): Recallable =
  ## deleteRevision
  ## This operation deletes a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_21626282 = newJObject()
  add(path_21626282, "RevisionId", newJString(RevisionId))
  add(path_21626282, "DataSetId", newJString(DataSetId))
  result = call_21626281.call(path_21626282, nil, nil, nil, nil)

var deleteRevision* = Call_DeleteRevision_21626268(name: "deleteRevision",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_DeleteRevision_21626269, base: "/",
    makeUrl: url_DeleteRevision_21626270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRevisionAssets_21626300 = ref object of OpenApiRestCall_21625435
proc url_ListRevisionAssets_21626302(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRevisionAssets_21626301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_21626303 = path.getOrDefault("RevisionId")
  valid_21626303 = validateParameter(valid_21626303, JString, required = true,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "RevisionId", valid_21626303
  var valid_21626304 = path.getOrDefault("DataSetId")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "DataSetId", valid_21626304
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626305 = query.getOrDefault("NextToken")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "NextToken", valid_21626305
  var valid_21626306 = query.getOrDefault("maxResults")
  valid_21626306 = validateParameter(valid_21626306, JInt, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "maxResults", valid_21626306
  var valid_21626307 = query.getOrDefault("nextToken")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "nextToken", valid_21626307
  var valid_21626308 = query.getOrDefault("MaxResults")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "MaxResults", valid_21626308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626309 = header.getOrDefault("X-Amz-Date")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Date", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Security-Token", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Algorithm", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Signature")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Signature", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Credential")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Credential", valid_21626315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626316: Call_ListRevisionAssets_21626300; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  let valid = call_21626316.validator(path, query, header, formData, body, _)
  let scheme = call_21626316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626316.makeUrl(scheme.get, call_21626316.host, call_21626316.base,
                               call_21626316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626316, uri, valid, _)

proc call*(call_21626317: Call_ListRevisionAssets_21626300; RevisionId: string;
          DataSetId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRevisionAssets
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626318 = newJObject()
  var query_21626319 = newJObject()
  add(query_21626319, "NextToken", newJString(NextToken))
  add(query_21626319, "maxResults", newJInt(maxResults))
  add(query_21626319, "nextToken", newJString(nextToken))
  add(path_21626318, "RevisionId", newJString(RevisionId))
  add(path_21626318, "DataSetId", newJString(DataSetId))
  add(query_21626319, "MaxResults", newJString(MaxResults))
  result = call_21626317.call(path_21626318, query_21626319, nil, nil, nil)

var listRevisionAssets* = Call_ListRevisionAssets_21626300(
    name: "listRevisionAssets", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets",
    validator: validate_ListRevisionAssets_21626301, base: "/",
    makeUrl: url_ListRevisionAssets_21626302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626334 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626336(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626335(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626337 = path.getOrDefault("resource-arn")
  valid_21626337 = validateParameter(valid_21626337, JString, required = true,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "resource-arn", valid_21626337
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626338 = header.getOrDefault("X-Amz-Date")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Date", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Security-Token", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Algorithm", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Signature")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Signature", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Credential")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Credential", valid_21626344
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

proc call*(call_21626346: Call_TagResource_21626334; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation tags a resource.
  ## 
  let valid = call_21626346.validator(path, query, header, formData, body, _)
  let scheme = call_21626346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626346.makeUrl(scheme.get, call_21626346.host, call_21626346.base,
                               call_21626346.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626346, uri, valid, _)

proc call*(call_21626347: Call_TagResource_21626334; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## This operation tags a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   body: JObject (required)
  var path_21626348 = newJObject()
  var body_21626349 = newJObject()
  add(path_21626348, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21626349 = body
  result = call_21626347.call(path_21626348, nil, nil, nil, body_21626349)

var tagResource* = Call_TagResource_21626334(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_21626335,
    base: "/", makeUrl: url_TagResource_21626336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626320 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626322(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626321(path: JsonNode; query: JsonNode;
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
  var valid_21626323 = path.getOrDefault("resource-arn")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "resource-arn", valid_21626323
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626324 = header.getOrDefault("X-Amz-Date")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Date", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Security-Token", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Algorithm", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Signature")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Signature", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Credential")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Credential", valid_21626330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626331: Call_ListTagsForResource_21626320; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists the tags on the resource.
  ## 
  let valid = call_21626331.validator(path, query, header, formData, body, _)
  let scheme = call_21626331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626331.makeUrl(scheme.get, call_21626331.host, call_21626331.base,
                               call_21626331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626331, uri, valid, _)

proc call*(call_21626332: Call_ListTagsForResource_21626320; resourceArn: string): Recallable =
  ## listTagsForResource
  ## This operation lists the tags on the resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_21626333 = newJObject()
  add(path_21626333, "resource-arn", newJString(resourceArn))
  result = call_21626332.call(path_21626333, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626320(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_21626321, base: "/",
    makeUrl: url_ListTagsForResource_21626322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626350 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626352(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626351(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626353 = path.getOrDefault("resource-arn")
  valid_21626353 = validateParameter(valid_21626353, JString, required = true,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "resource-arn", valid_21626353
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626354 = query.getOrDefault("tagKeys")
  valid_21626354 = validateParameter(valid_21626354, JArray, required = true,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "tagKeys", valid_21626354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626355 = header.getOrDefault("X-Amz-Date")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Date", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Security-Token", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Algorithm", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Signature")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Signature", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Credential")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Credential", valid_21626361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626362: Call_UntagResource_21626350; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation removes one or more tags from a resource.
  ## 
  let valid = call_21626362.validator(path, query, header, formData, body, _)
  let scheme = call_21626362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626362.makeUrl(scheme.get, call_21626362.host, call_21626362.base,
                               call_21626362.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626362, uri, valid, _)

proc call*(call_21626363: Call_UntagResource_21626350; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## This operation removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_21626364 = newJObject()
  var query_21626365 = newJObject()
  if tagKeys != nil:
    query_21626365.add "tagKeys", tagKeys
  add(path_21626364, "resource-arn", newJString(resourceArn))
  result = call_21626363.call(path_21626364, query_21626365, nil, nil, nil)

var untagResource* = Call_UntagResource_21626350(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_21626351,
    base: "/", makeUrl: url_UntagResource_21626352,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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