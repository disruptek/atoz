
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetJob_599705 = ref object of OpenApiRestCall_599368
proc url_GetJob_599707(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_599833 = path.getOrDefault("JobId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "JobId", valid_599833
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
  var valid_599834 = header.getOrDefault("X-Amz-Date")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Date", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Security-Token")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Security-Token", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_GetJob_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_GetJob_599705; JobId: string): Recallable =
  ## getJob
  ## This operation returns information about a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_599935 = newJObject()
  add(path_599935, "JobId", newJString(JobId))
  result = call_599934.call(path_599935, nil, nil, nil, nil)

var getJob* = Call_GetJob_599705(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "dataexchange.amazonaws.com",
                              route: "/v1/jobs/{JobId}",
                              validator: validate_GetJob_599706, base: "/",
                              url: url_GetJob_599707,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_599989 = ref object of OpenApiRestCall_599368
proc url_StartJob_599991(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_599990(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation starts a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_599992 = path.getOrDefault("JobId")
  valid_599992 = validateParameter(valid_599992, JString, required = true,
                                 default = nil)
  if valid_599992 != nil:
    section.add "JobId", valid_599992
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
  var valid_599993 = header.getOrDefault("X-Amz-Date")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Date", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Security-Token")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Security-Token", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600000: Call_StartJob_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation starts a job.
  ## 
  let valid = call_600000.validator(path, query, header, formData, body)
  let scheme = call_600000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600000.url(scheme.get, call_600000.host, call_600000.base,
                         call_600000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600000, url, valid)

proc call*(call_600001: Call_StartJob_599989; JobId: string): Recallable =
  ## startJob
  ## This operation starts a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_600002 = newJObject()
  add(path_600002, "JobId", newJString(JobId))
  result = call_600001.call(path_600002, nil, nil, nil, nil)

var startJob* = Call_StartJob_599989(name: "startJob", meth: HttpMethod.HttpPatch,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs/{JobId}",
                                  validator: validate_StartJob_599990, base: "/",
                                  url: url_StartJob_599991,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_599975 = ref object of OpenApiRestCall_599368
proc url_CancelJob_599977(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_599976(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_599978 = path.getOrDefault("JobId")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "JobId", valid_599978
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
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CancelJob_599975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CancelJob_599975; JobId: string): Recallable =
  ## cancelJob
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_599988 = newJObject()
  add(path_599988, "JobId", newJString(JobId))
  result = call_599987.call(path_599988, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_599975(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs/{JobId}",
                                    validator: validate_CancelJob_599976,
                                    base: "/", url: url_CancelJob_599977,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_600021 = ref object of OpenApiRestCall_599368
proc url_CreateDataSet_600023(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSet_600022(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600024 = header.getOrDefault("X-Amz-Date")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Date", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Security-Token")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Security-Token", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_CreateDataSet_600021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a data set.
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_CreateDataSet_600021; body: JsonNode): Recallable =
  ## createDataSet
  ## This operation creates a data set.
  ##   body: JObject (required)
  var body_600034 = newJObject()
  if body != nil:
    body_600034 = body
  result = call_600033.call(nil, nil, nil, nil, body_600034)

var createDataSet* = Call_CreateDataSet_600021(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_CreateDataSet_600022, base: "/",
    url: url_CreateDataSet_600023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_600003 = ref object of OpenApiRestCall_599368
proc url_ListDataSets_600005(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataSets_600004(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600006 = query.getOrDefault("origin")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "origin", valid_600006
  var valid_600007 = query.getOrDefault("NextToken")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "NextToken", valid_600007
  var valid_600008 = query.getOrDefault("maxResults")
  valid_600008 = validateParameter(valid_600008, JInt, required = false, default = nil)
  if valid_600008 != nil:
    section.add "maxResults", valid_600008
  var valid_600009 = query.getOrDefault("nextToken")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "nextToken", valid_600009
  var valid_600010 = query.getOrDefault("MaxResults")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "MaxResults", valid_600010
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
  var valid_600011 = header.getOrDefault("X-Amz-Date")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Date", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Security-Token")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Security-Token", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Content-Sha256", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Algorithm")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Algorithm", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Signature")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Signature", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-SignedHeaders", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Credential")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Credential", valid_600017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600018: Call_ListDataSets_600003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  let valid = call_600018.validator(path, query, header, formData, body)
  let scheme = call_600018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600018.url(scheme.get, call_600018.host, call_600018.base,
                         call_600018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600018, url, valid)

proc call*(call_600019: Call_ListDataSets_600003; origin: string = "";
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
  var query_600020 = newJObject()
  add(query_600020, "origin", newJString(origin))
  add(query_600020, "NextToken", newJString(NextToken))
  add(query_600020, "maxResults", newJInt(maxResults))
  add(query_600020, "nextToken", newJString(nextToken))
  add(query_600020, "MaxResults", newJString(MaxResults))
  result = call_600019.call(nil, query_600020, nil, nil, nil)

var listDataSets* = Call_ListDataSets_600003(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_ListDataSets_600004, base: "/",
    url: url_ListDataSets_600005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_600054 = ref object of OpenApiRestCall_599368
proc url_CreateJob_600056(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_600055(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600057 = header.getOrDefault("X-Amz-Date")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Date", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Security-Token")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Security-Token", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Content-Sha256", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Algorithm")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Algorithm", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Signature")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Signature", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-SignedHeaders", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Credential")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Credential", valid_600063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600065: Call_CreateJob_600054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a job.
  ## 
  let valid = call_600065.validator(path, query, header, formData, body)
  let scheme = call_600065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600065.url(scheme.get, call_600065.host, call_600065.base,
                         call_600065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600065, url, valid)

proc call*(call_600066: Call_CreateJob_600054; body: JsonNode): Recallable =
  ## createJob
  ## This operation creates a job.
  ##   body: JObject (required)
  var body_600067 = newJObject()
  if body != nil:
    body_600067 = body
  result = call_600066.call(nil, nil, nil, nil, body_600067)

var createJob* = Call_CreateJob_600054(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs",
                                    validator: validate_CreateJob_600055,
                                    base: "/", url: url_CreateJob_600056,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_600035 = ref object of OpenApiRestCall_599368
proc url_ListJobs_600037(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_600036(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600038 = query.getOrDefault("dataSetId")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "dataSetId", valid_600038
  var valid_600039 = query.getOrDefault("NextToken")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "NextToken", valid_600039
  var valid_600040 = query.getOrDefault("maxResults")
  valid_600040 = validateParameter(valid_600040, JInt, required = false, default = nil)
  if valid_600040 != nil:
    section.add "maxResults", valid_600040
  var valid_600041 = query.getOrDefault("nextToken")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "nextToken", valid_600041
  var valid_600042 = query.getOrDefault("revisionId")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "revisionId", valid_600042
  var valid_600043 = query.getOrDefault("MaxResults")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "MaxResults", valid_600043
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
  var valid_600044 = header.getOrDefault("X-Amz-Date")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Date", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Security-Token")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Security-Token", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Content-Sha256", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Algorithm")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Algorithm", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Signature")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Signature", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-SignedHeaders", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Credential")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Credential", valid_600050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600051: Call_ListJobs_600035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  let valid = call_600051.validator(path, query, header, formData, body)
  let scheme = call_600051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600051.url(scheme.get, call_600051.host, call_600051.base,
                         call_600051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600051, url, valid)

proc call*(call_600052: Call_ListJobs_600035; dataSetId: string = "";
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
  var query_600053 = newJObject()
  add(query_600053, "dataSetId", newJString(dataSetId))
  add(query_600053, "NextToken", newJString(NextToken))
  add(query_600053, "maxResults", newJInt(maxResults))
  add(query_600053, "nextToken", newJString(nextToken))
  add(query_600053, "revisionId", newJString(revisionId))
  add(query_600053, "MaxResults", newJString(MaxResults))
  result = call_600052.call(nil, query_600053, nil, nil, nil)

var listJobs* = Call_ListJobs_600035(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs", validator: validate_ListJobs_600036,
                                  base: "/", url: url_ListJobs_600037,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRevision_600087 = ref object of OpenApiRestCall_599368
proc url_CreateRevision_600089(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRevision_600088(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation creates a revision for a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_600090 = path.getOrDefault("DataSetId")
  valid_600090 = validateParameter(valid_600090, JString, required = true,
                                 default = nil)
  if valid_600090 != nil:
    section.add "DataSetId", valid_600090
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
  var valid_600091 = header.getOrDefault("X-Amz-Date")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Date", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Security-Token")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Security-Token", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Content-Sha256", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Algorithm")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Algorithm", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Signature")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Signature", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-SignedHeaders", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Credential")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Credential", valid_600097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600099: Call_CreateRevision_600087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a revision for a data set.
  ## 
  let valid = call_600099.validator(path, query, header, formData, body)
  let scheme = call_600099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600099.url(scheme.get, call_600099.host, call_600099.base,
                         call_600099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600099, url, valid)

proc call*(call_600100: Call_CreateRevision_600087; body: JsonNode; DataSetId: string): Recallable =
  ## createRevision
  ## This operation creates a revision for a data set.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600101 = newJObject()
  var body_600102 = newJObject()
  if body != nil:
    body_600102 = body
  add(path_600101, "DataSetId", newJString(DataSetId))
  result = call_600100.call(path_600101, nil, nil, nil, body_600102)

var createRevision* = Call_CreateRevision_600087(name: "createRevision",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_CreateRevision_600088, base: "/", url: url_CreateRevision_600089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSetRevisions_600068 = ref object of OpenApiRestCall_599368
proc url_ListDataSetRevisions_600070(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSetRevisions_600069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_600071 = path.getOrDefault("DataSetId")
  valid_600071 = validateParameter(valid_600071, JString, required = true,
                                 default = nil)
  if valid_600071 != nil:
    section.add "DataSetId", valid_600071
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
  var valid_600072 = query.getOrDefault("NextToken")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "NextToken", valid_600072
  var valid_600073 = query.getOrDefault("maxResults")
  valid_600073 = validateParameter(valid_600073, JInt, required = false, default = nil)
  if valid_600073 != nil:
    section.add "maxResults", valid_600073
  var valid_600074 = query.getOrDefault("nextToken")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "nextToken", valid_600074
  var valid_600075 = query.getOrDefault("MaxResults")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "MaxResults", valid_600075
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
  var valid_600076 = header.getOrDefault("X-Amz-Date")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Date", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Security-Token")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Security-Token", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Content-Sha256", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Algorithm")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Algorithm", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Signature")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Signature", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-SignedHeaders", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Credential")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Credential", valid_600082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600083: Call_ListDataSetRevisions_600068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  let valid = call_600083.validator(path, query, header, formData, body)
  let scheme = call_600083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600083.url(scheme.get, call_600083.host, call_600083.base,
                         call_600083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600083, url, valid)

proc call*(call_600084: Call_ListDataSetRevisions_600068; DataSetId: string;
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
  var path_600085 = newJObject()
  var query_600086 = newJObject()
  add(query_600086, "NextToken", newJString(NextToken))
  add(query_600086, "maxResults", newJInt(maxResults))
  add(query_600086, "nextToken", newJString(nextToken))
  add(path_600085, "DataSetId", newJString(DataSetId))
  add(query_600086, "MaxResults", newJString(MaxResults))
  result = call_600084.call(path_600085, query_600086, nil, nil, nil)

var listDataSetRevisions* = Call_ListDataSetRevisions_600068(
    name: "listDataSetRevisions", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_ListDataSetRevisions_600069, base: "/",
    url: url_ListDataSetRevisions_600070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAsset_600103 = ref object of OpenApiRestCall_599368
proc url_GetAsset_600105(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAsset_600104(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600106 = path.getOrDefault("RevisionId")
  valid_600106 = validateParameter(valid_600106, JString, required = true,
                                 default = nil)
  if valid_600106 != nil:
    section.add "RevisionId", valid_600106
  var valid_600107 = path.getOrDefault("AssetId")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "AssetId", valid_600107
  var valid_600108 = path.getOrDefault("DataSetId")
  valid_600108 = validateParameter(valid_600108, JString, required = true,
                                 default = nil)
  if valid_600108 != nil:
    section.add "DataSetId", valid_600108
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
  var valid_600109 = header.getOrDefault("X-Amz-Date")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Date", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Security-Token")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Security-Token", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Content-Sha256", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Algorithm")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Algorithm", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Signature")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Signature", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-SignedHeaders", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Credential")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Credential", valid_600115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600116: Call_GetAsset_600103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about an asset.
  ## 
  let valid = call_600116.validator(path, query, header, formData, body)
  let scheme = call_600116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600116.url(scheme.get, call_600116.host, call_600116.base,
                         call_600116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600116, url, valid)

proc call*(call_600117: Call_GetAsset_600103; RevisionId: string; AssetId: string;
          DataSetId: string): Recallable =
  ## getAsset
  ## This operation returns information about an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600118 = newJObject()
  add(path_600118, "RevisionId", newJString(RevisionId))
  add(path_600118, "AssetId", newJString(AssetId))
  add(path_600118, "DataSetId", newJString(DataSetId))
  result = call_600117.call(path_600118, nil, nil, nil, nil)

var getAsset* = Call_GetAsset_600103(name: "getAsset", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                  validator: validate_GetAsset_600104, base: "/",
                                  url: url_GetAsset_600105,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAsset_600135 = ref object of OpenApiRestCall_599368
proc url_UpdateAsset_600137(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAsset_600136(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600138 = path.getOrDefault("RevisionId")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = nil)
  if valid_600138 != nil:
    section.add "RevisionId", valid_600138
  var valid_600139 = path.getOrDefault("AssetId")
  valid_600139 = validateParameter(valid_600139, JString, required = true,
                                 default = nil)
  if valid_600139 != nil:
    section.add "AssetId", valid_600139
  var valid_600140 = path.getOrDefault("DataSetId")
  valid_600140 = validateParameter(valid_600140, JString, required = true,
                                 default = nil)
  if valid_600140 != nil:
    section.add "DataSetId", valid_600140
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
  var valid_600141 = header.getOrDefault("X-Amz-Date")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Date", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Security-Token")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Security-Token", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Content-Sha256", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Algorithm")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Algorithm", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Signature")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Signature", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-SignedHeaders", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Credential")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Credential", valid_600147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600149: Call_UpdateAsset_600135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates an asset.
  ## 
  let valid = call_600149.validator(path, query, header, formData, body)
  let scheme = call_600149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600149.url(scheme.get, call_600149.host, call_600149.base,
                         call_600149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600149, url, valid)

proc call*(call_600150: Call_UpdateAsset_600135; RevisionId: string; AssetId: string;
          body: JsonNode; DataSetId: string): Recallable =
  ## updateAsset
  ## This operation updates an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600151 = newJObject()
  var body_600152 = newJObject()
  add(path_600151, "RevisionId", newJString(RevisionId))
  add(path_600151, "AssetId", newJString(AssetId))
  if body != nil:
    body_600152 = body
  add(path_600151, "DataSetId", newJString(DataSetId))
  result = call_600150.call(path_600151, nil, nil, nil, body_600152)

var updateAsset* = Call_UpdateAsset_600135(name: "updateAsset",
                                        meth: HttpMethod.HttpPatch,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_UpdateAsset_600136,
                                        base: "/", url: url_UpdateAsset_600137,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_600119 = ref object of OpenApiRestCall_599368
proc url_DeleteAsset_600121(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_600120(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600122 = path.getOrDefault("RevisionId")
  valid_600122 = validateParameter(valid_600122, JString, required = true,
                                 default = nil)
  if valid_600122 != nil:
    section.add "RevisionId", valid_600122
  var valid_600123 = path.getOrDefault("AssetId")
  valid_600123 = validateParameter(valid_600123, JString, required = true,
                                 default = nil)
  if valid_600123 != nil:
    section.add "AssetId", valid_600123
  var valid_600124 = path.getOrDefault("DataSetId")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = nil)
  if valid_600124 != nil:
    section.add "DataSetId", valid_600124
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
  var valid_600125 = header.getOrDefault("X-Amz-Date")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Date", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Security-Token")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Security-Token", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Content-Sha256", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Algorithm")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Algorithm", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Signature")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Signature", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-SignedHeaders", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Credential")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Credential", valid_600131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600132: Call_DeleteAsset_600119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes an asset.
  ## 
  let valid = call_600132.validator(path, query, header, formData, body)
  let scheme = call_600132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600132.url(scheme.get, call_600132.host, call_600132.base,
                         call_600132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600132, url, valid)

proc call*(call_600133: Call_DeleteAsset_600119; RevisionId: string; AssetId: string;
          DataSetId: string): Recallable =
  ## deleteAsset
  ## This operation deletes an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600134 = newJObject()
  add(path_600134, "RevisionId", newJString(RevisionId))
  add(path_600134, "AssetId", newJString(AssetId))
  add(path_600134, "DataSetId", newJString(DataSetId))
  result = call_600133.call(path_600134, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_600119(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_DeleteAsset_600120,
                                        base: "/", url: url_DeleteAsset_600121,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSet_600153 = ref object of OpenApiRestCall_599368
proc url_GetDataSet_600155(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSet_600154(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_600156 = path.getOrDefault("DataSetId")
  valid_600156 = validateParameter(valid_600156, JString, required = true,
                                 default = nil)
  if valid_600156 != nil:
    section.add "DataSetId", valid_600156
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600164: Call_GetDataSet_600153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a data set.
  ## 
  let valid = call_600164.validator(path, query, header, formData, body)
  let scheme = call_600164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600164.url(scheme.get, call_600164.host, call_600164.base,
                         call_600164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600164, url, valid)

proc call*(call_600165: Call_GetDataSet_600153; DataSetId: string): Recallable =
  ## getDataSet
  ## This operation returns information about a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600166 = newJObject()
  add(path_600166, "DataSetId", newJString(DataSetId))
  result = call_600165.call(path_600166, nil, nil, nil, nil)

var getDataSet* = Call_GetDataSet_600153(name: "getDataSet",
                                      meth: HttpMethod.HttpGet,
                                      host: "dataexchange.amazonaws.com",
                                      route: "/v1/data-sets/{DataSetId}",
                                      validator: validate_GetDataSet_600154,
                                      base: "/", url: url_GetDataSet_600155,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_600181 = ref object of OpenApiRestCall_599368
proc url_UpdateDataSet_600183(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_600182(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_600184 = path.getOrDefault("DataSetId")
  valid_600184 = validateParameter(valid_600184, JString, required = true,
                                 default = nil)
  if valid_600184 != nil:
    section.add "DataSetId", valid_600184
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
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Content-Sha256", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Algorithm")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Algorithm", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Signature")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Signature", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-SignedHeaders", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Credential")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Credential", valid_600191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600193: Call_UpdateDataSet_600181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a data set.
  ## 
  let valid = call_600193.validator(path, query, header, formData, body)
  let scheme = call_600193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600193.url(scheme.get, call_600193.host, call_600193.base,
                         call_600193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600193, url, valid)

proc call*(call_600194: Call_UpdateDataSet_600181; body: JsonNode; DataSetId: string): Recallable =
  ## updateDataSet
  ## This operation updates a data set.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600195 = newJObject()
  var body_600196 = newJObject()
  if body != nil:
    body_600196 = body
  add(path_600195, "DataSetId", newJString(DataSetId))
  result = call_600194.call(path_600195, nil, nil, nil, body_600196)

var updateDataSet* = Call_UpdateDataSet_600181(name: "updateDataSet",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_UpdateDataSet_600182,
    base: "/", url: url_UpdateDataSet_600183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_600167 = ref object of OpenApiRestCall_599368
proc url_DeleteDataSet_600169(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_600168(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_600170 = path.getOrDefault("DataSetId")
  valid_600170 = validateParameter(valid_600170, JString, required = true,
                                 default = nil)
  if valid_600170 != nil:
    section.add "DataSetId", valid_600170
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
  var valid_600171 = header.getOrDefault("X-Amz-Date")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Date", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Security-Token")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Security-Token", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Content-Sha256", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Algorithm")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Algorithm", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Signature")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Signature", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-SignedHeaders", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Credential")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Credential", valid_600177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600178: Call_DeleteDataSet_600167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a data set.
  ## 
  let valid = call_600178.validator(path, query, header, formData, body)
  let scheme = call_600178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600178.url(scheme.get, call_600178.host, call_600178.base,
                         call_600178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600178, url, valid)

proc call*(call_600179: Call_DeleteDataSet_600167; DataSetId: string): Recallable =
  ## deleteDataSet
  ## This operation deletes a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600180 = newJObject()
  add(path_600180, "DataSetId", newJString(DataSetId))
  result = call_600179.call(path_600180, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_600167(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_DeleteDataSet_600168,
    base: "/", url: url_DeleteDataSet_600169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_600197 = ref object of OpenApiRestCall_599368
proc url_GetRevision_600199(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_600198(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600200 = path.getOrDefault("RevisionId")
  valid_600200 = validateParameter(valid_600200, JString, required = true,
                                 default = nil)
  if valid_600200 != nil:
    section.add "RevisionId", valid_600200
  var valid_600201 = path.getOrDefault("DataSetId")
  valid_600201 = validateParameter(valid_600201, JString, required = true,
                                 default = nil)
  if valid_600201 != nil:
    section.add "DataSetId", valid_600201
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
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Content-Sha256", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Algorithm")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Algorithm", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Signature")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Signature", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-SignedHeaders", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Credential")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Credential", valid_600208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_GetRevision_600197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a revision.
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_GetRevision_600197; RevisionId: string;
          DataSetId: string): Recallable =
  ## getRevision
  ## This operation returns information about a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600211 = newJObject()
  add(path_600211, "RevisionId", newJString(RevisionId))
  add(path_600211, "DataSetId", newJString(DataSetId))
  result = call_600210.call(path_600211, nil, nil, nil, nil)

var getRevision* = Call_GetRevision_600197(name: "getRevision",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
                                        validator: validate_GetRevision_600198,
                                        base: "/", url: url_GetRevision_600199,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRevision_600227 = ref object of OpenApiRestCall_599368
proc url_UpdateRevision_600229(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRevision_600228(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600230 = path.getOrDefault("RevisionId")
  valid_600230 = validateParameter(valid_600230, JString, required = true,
                                 default = nil)
  if valid_600230 != nil:
    section.add "RevisionId", valid_600230
  var valid_600231 = path.getOrDefault("DataSetId")
  valid_600231 = validateParameter(valid_600231, JString, required = true,
                                 default = nil)
  if valid_600231 != nil:
    section.add "DataSetId", valid_600231
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
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Content-Sha256", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Algorithm")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Algorithm", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Signature")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Signature", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-SignedHeaders", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Credential")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Credential", valid_600238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600240: Call_UpdateRevision_600227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a revision.
  ## 
  let valid = call_600240.validator(path, query, header, formData, body)
  let scheme = call_600240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600240.url(scheme.get, call_600240.host, call_600240.base,
                         call_600240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600240, url, valid)

proc call*(call_600241: Call_UpdateRevision_600227; RevisionId: string;
          body: JsonNode; DataSetId: string): Recallable =
  ## updateRevision
  ## This operation updates a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600242 = newJObject()
  var body_600243 = newJObject()
  add(path_600242, "RevisionId", newJString(RevisionId))
  if body != nil:
    body_600243 = body
  add(path_600242, "DataSetId", newJString(DataSetId))
  result = call_600241.call(path_600242, nil, nil, nil, body_600243)

var updateRevision* = Call_UpdateRevision_600227(name: "updateRevision",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_UpdateRevision_600228, base: "/", url: url_UpdateRevision_600229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRevision_600212 = ref object of OpenApiRestCall_599368
proc url_DeleteRevision_600214(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRevision_600213(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600215 = path.getOrDefault("RevisionId")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "RevisionId", valid_600215
  var valid_600216 = path.getOrDefault("DataSetId")
  valid_600216 = validateParameter(valid_600216, JString, required = true,
                                 default = nil)
  if valid_600216 != nil:
    section.add "DataSetId", valid_600216
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
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Content-Sha256", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Algorithm")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Algorithm", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Signature")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Signature", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-SignedHeaders", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Credential")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Credential", valid_600223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600224: Call_DeleteRevision_600212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a revision.
  ## 
  let valid = call_600224.validator(path, query, header, formData, body)
  let scheme = call_600224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600224.url(scheme.get, call_600224.host, call_600224.base,
                         call_600224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600224, url, valid)

proc call*(call_600225: Call_DeleteRevision_600212; RevisionId: string;
          DataSetId: string): Recallable =
  ## deleteRevision
  ## This operation deletes a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_600226 = newJObject()
  add(path_600226, "RevisionId", newJString(RevisionId))
  add(path_600226, "DataSetId", newJString(DataSetId))
  result = call_600225.call(path_600226, nil, nil, nil, nil)

var deleteRevision* = Call_DeleteRevision_600212(name: "deleteRevision",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_DeleteRevision_600213, base: "/", url: url_DeleteRevision_600214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRevisionAssets_600244 = ref object of OpenApiRestCall_599368
proc url_ListRevisionAssets_600246(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRevisionAssets_600245(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600247 = path.getOrDefault("RevisionId")
  valid_600247 = validateParameter(valid_600247, JString, required = true,
                                 default = nil)
  if valid_600247 != nil:
    section.add "RevisionId", valid_600247
  var valid_600248 = path.getOrDefault("DataSetId")
  valid_600248 = validateParameter(valid_600248, JString, required = true,
                                 default = nil)
  if valid_600248 != nil:
    section.add "DataSetId", valid_600248
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
  var valid_600249 = query.getOrDefault("NextToken")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "NextToken", valid_600249
  var valid_600250 = query.getOrDefault("maxResults")
  valid_600250 = validateParameter(valid_600250, JInt, required = false, default = nil)
  if valid_600250 != nil:
    section.add "maxResults", valid_600250
  var valid_600251 = query.getOrDefault("nextToken")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "nextToken", valid_600251
  var valid_600252 = query.getOrDefault("MaxResults")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "MaxResults", valid_600252
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
  var valid_600253 = header.getOrDefault("X-Amz-Date")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Date", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Security-Token")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Security-Token", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Content-Sha256", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Algorithm")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Algorithm", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Signature")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Signature", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-SignedHeaders", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Credential")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Credential", valid_600259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600260: Call_ListRevisionAssets_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  let valid = call_600260.validator(path, query, header, formData, body)
  let scheme = call_600260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600260.url(scheme.get, call_600260.host, call_600260.base,
                         call_600260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600260, url, valid)

proc call*(call_600261: Call_ListRevisionAssets_600244; RevisionId: string;
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
  var path_600262 = newJObject()
  var query_600263 = newJObject()
  add(query_600263, "NextToken", newJString(NextToken))
  add(query_600263, "maxResults", newJInt(maxResults))
  add(query_600263, "nextToken", newJString(nextToken))
  add(path_600262, "RevisionId", newJString(RevisionId))
  add(path_600262, "DataSetId", newJString(DataSetId))
  add(query_600263, "MaxResults", newJString(MaxResults))
  result = call_600261.call(path_600262, query_600263, nil, nil, nil)

var listRevisionAssets* = Call_ListRevisionAssets_600244(
    name: "listRevisionAssets", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets",
    validator: validate_ListRevisionAssets_600245, base: "/",
    url: url_ListRevisionAssets_600246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600278 = ref object of OpenApiRestCall_599368
proc url_TagResource_600280(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_600279(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600281 = path.getOrDefault("resource-arn")
  valid_600281 = validateParameter(valid_600281, JString, required = true,
                                 default = nil)
  if valid_600281 != nil:
    section.add "resource-arn", valid_600281
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
  var valid_600282 = header.getOrDefault("X-Amz-Date")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Date", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Security-Token")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Security-Token", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Content-Sha256", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Algorithm")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Algorithm", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Signature")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Signature", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-SignedHeaders", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Credential")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Credential", valid_600288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600290: Call_TagResource_600278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation tags a resource.
  ## 
  let valid = call_600290.validator(path, query, header, formData, body)
  let scheme = call_600290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600290.url(scheme.get, call_600290.host, call_600290.base,
                         call_600290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600290, url, valid)

proc call*(call_600291: Call_TagResource_600278; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## This operation tags a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   body: JObject (required)
  var path_600292 = newJObject()
  var body_600293 = newJObject()
  add(path_600292, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_600293 = body
  result = call_600291.call(path_600292, nil, nil, nil, body_600293)

var tagResource* = Call_TagResource_600278(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_600279,
                                        base: "/", url: url_TagResource_600280,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600264 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600266(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_600265(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600267 = path.getOrDefault("resource-arn")
  valid_600267 = validateParameter(valid_600267, JString, required = true,
                                 default = nil)
  if valid_600267 != nil:
    section.add "resource-arn", valid_600267
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
  var valid_600268 = header.getOrDefault("X-Amz-Date")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Date", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Security-Token")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Security-Token", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Content-Sha256", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-Algorithm")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Algorithm", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Signature")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Signature", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-SignedHeaders", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Credential")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Credential", valid_600274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600275: Call_ListTagsForResource_600264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists the tags on the resource.
  ## 
  let valid = call_600275.validator(path, query, header, formData, body)
  let scheme = call_600275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600275.url(scheme.get, call_600275.host, call_600275.base,
                         call_600275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600275, url, valid)

proc call*(call_600276: Call_ListTagsForResource_600264; resourceArn: string): Recallable =
  ## listTagsForResource
  ## This operation lists the tags on the resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_600277 = newJObject()
  add(path_600277, "resource-arn", newJString(resourceArn))
  result = call_600276.call(path_600277, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600264(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_600265, base: "/",
    url: url_ListTagsForResource_600266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600294 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600296(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_600295(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600297 = path.getOrDefault("resource-arn")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = nil)
  if valid_600297 != nil:
    section.add "resource-arn", valid_600297
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600298 = query.getOrDefault("tagKeys")
  valid_600298 = validateParameter(valid_600298, JArray, required = true, default = nil)
  if valid_600298 != nil:
    section.add "tagKeys", valid_600298
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
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Content-Sha256", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Algorithm")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Algorithm", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Signature")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Signature", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-SignedHeaders", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Credential")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Credential", valid_600305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600306: Call_UntagResource_600294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes one or more tags from a resource.
  ## 
  let valid = call_600306.validator(path, query, header, formData, body)
  let scheme = call_600306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600306.url(scheme.get, call_600306.host, call_600306.base,
                         call_600306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600306, url, valid)

proc call*(call_600307: Call_UntagResource_600294; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## This operation removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_600308 = newJObject()
  var query_600309 = newJObject()
  if tagKeys != nil:
    query_600309.add "tagKeys", tagKeys
  add(path_600308, "resource-arn", newJString(resourceArn))
  result = call_600307.call(path_600308, query_600309, nil, nil, nil)

var untagResource* = Call_UntagResource_600294(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_600295,
    base: "/", url: url_UntagResource_600296, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
