
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS S3 Control
## version: 2018-08-20
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  AWS S3 Control provides access to Amazon S3 control plane operations. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/s3-control/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com", "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
                           "us-west-2": "s3-control.us-west-2.amazonaws.com",
                           "eu-west-2": "s3-control.eu-west-2.amazonaws.com", "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com", "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
                           "us-east-2": "s3-control.us-east-2.amazonaws.com",
                           "us-east-1": "s3-control.us-east-1.amazonaws.com", "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
                           "eu-north-1": "s3-control.eu-north-1.amazonaws.com", "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
                           "us-west-1": "s3-control.us-west-1.amazonaws.com", "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "s3-control.eu-west-3.amazonaws.com", "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
                           "eu-west-1": "s3-control.eu-west-1.amazonaws.com", "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com", "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com", "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
      "us-west-2": "s3-control.us-west-2.amazonaws.com",
      "eu-west-2": "s3-control.eu-west-2.amazonaws.com",
      "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com",
      "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
      "us-east-2": "s3-control.us-east-2.amazonaws.com",
      "us-east-1": "s3-control.us-east-1.amazonaws.com",
      "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
      "eu-north-1": "s3-control.eu-north-1.amazonaws.com",
      "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
      "us-west-1": "s3-control.us-west-1.amazonaws.com",
      "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
      "eu-west-3": "s3-control.eu-west-3.amazonaws.com",
      "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
      "eu-west-1": "s3-control.eu-west-1.amazonaws.com",
      "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com",
      "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "s3control"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateJob_599966 = ref object of OpenApiRestCall_599368
proc url_CreateJob_599968(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_599967(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon S3 batch operations job.
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_599969 = header.getOrDefault("X-Amz-Date")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Date", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Security-Token")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Security-Token", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Content-Sha256", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Algorithm")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Algorithm", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Signature")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Signature", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-SignedHeaders", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-Credential")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Credential", valid_599975
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_599976 = header.getOrDefault("x-amz-account-id")
  valid_599976 = validateParameter(valid_599976, JString, required = true,
                                 default = nil)
  if valid_599976 != nil:
    section.add "x-amz-account-id", valid_599976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599978: Call_CreateJob_599966; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon S3 batch operations job.
  ## 
  let valid = call_599978.validator(path, query, header, formData, body)
  let scheme = call_599978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599978.url(scheme.get, call_599978.host, call_599978.base,
                         call_599978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599978, url, valid)

proc call*(call_599979: Call_CreateJob_599966; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_599980 = newJObject()
  if body != nil:
    body_599980 = body
  result = call_599979.call(nil, nil, nil, nil, body_599980)

var createJob* = Call_CreateJob_599966(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "s3-control.amazonaws.com",
                                    route: "/v20180820/jobs#x-amz-account-id",
                                    validator: validate_CreateJob_599967,
                                    base: "/", url: url_CreateJob_599968,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_599705 = ref object of OpenApiRestCall_599368
proc url_ListJobs_599707(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  ##   nextToken: JString
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_599819 = query.getOrDefault("jobStatuses")
  valid_599819 = validateParameter(valid_599819, JArray, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "jobStatuses", valid_599819
  var valid_599820 = query.getOrDefault("NextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "NextToken", valid_599820
  var valid_599821 = query.getOrDefault("maxResults")
  valid_599821 = validateParameter(valid_599821, JInt, required = false, default = nil)
  if valid_599821 != nil:
    section.add "maxResults", valid_599821
  var valid_599822 = query.getOrDefault("nextToken")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "nextToken", valid_599822
  var valid_599823 = query.getOrDefault("MaxResults")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "MaxResults", valid_599823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_599824 = header.getOrDefault("X-Amz-Date")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Date", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Security-Token")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Security-Token", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Content-Sha256", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Algorithm")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Algorithm", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Signature")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Signature", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-SignedHeaders", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Credential")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Credential", valid_599830
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_599831 = header.getOrDefault("x-amz-account-id")
  valid_599831 = validateParameter(valid_599831, JString, required = true,
                                 default = nil)
  if valid_599831 != nil:
    section.add "x-amz-account-id", valid_599831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599854: Call_ListJobs_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  let valid = call_599854.validator(path, query, header, formData, body)
  let scheme = call_599854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599854.url(scheme.get, call_599854.host, call_599854.base,
                         call_599854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599854, url, valid)

proc call*(call_599925: Call_ListJobs_599705; jobStatuses: JsonNode = nil;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  ##   nextToken: string
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_599926 = newJObject()
  if jobStatuses != nil:
    query_599926.add "jobStatuses", jobStatuses
  add(query_599926, "NextToken", newJString(NextToken))
  add(query_599926, "maxResults", newJInt(maxResults))
  add(query_599926, "nextToken", newJString(nextToken))
  add(query_599926, "MaxResults", newJString(MaxResults))
  result = call_599925.call(nil, query_599926, nil, nil, nil)

var listJobs* = Call_ListJobs_599705(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "s3-control.amazonaws.com",
                                  route: "/v20180820/jobs#x-amz-account-id",
                                  validator: validate_ListJobs_599706, base: "/",
                                  url: url_ListJobs_599707,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_599994 = ref object of OpenApiRestCall_599368
proc url_PutPublicAccessBlock_599996(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPublicAccessBlock_599995(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_599997 = header.getOrDefault("X-Amz-Date")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Date", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Security-Token")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Security-Token", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Content-Sha256", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Algorithm")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Algorithm", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Signature")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Signature", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-SignedHeaders", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Credential")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Credential", valid_600003
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_600004 = header.getOrDefault("x-amz-account-id")
  valid_600004 = validateParameter(valid_600004, JString, required = true,
                                 default = nil)
  if valid_600004 != nil:
    section.add "x-amz-account-id", valid_600004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_PutPublicAccessBlock_599994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_PutPublicAccessBlock_599994; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## <p/>
  ##   body: JObject (required)
  var body_600008 = newJObject()
  if body != nil:
    body_600008 = body
  result = call_600007.call(nil, nil, nil, nil, body_600008)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_599994(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_599995, base: "/",
    url: url_PutPublicAccessBlock_599996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_599981 = ref object of OpenApiRestCall_599368
proc url_GetPublicAccessBlock_599983(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublicAccessBlock_599982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_599984 = header.getOrDefault("X-Amz-Date")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Date", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Security-Token")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Security-Token", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Content-Sha256", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Algorithm")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Algorithm", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Signature")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Signature", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-SignedHeaders", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Credential")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Credential", valid_599990
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_599991 = header.getOrDefault("x-amz-account-id")
  valid_599991 = validateParameter(valid_599991, JString, required = true,
                                 default = nil)
  if valid_599991 != nil:
    section.add "x-amz-account-id", valid_599991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_GetPublicAccessBlock_599981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_GetPublicAccessBlock_599981): Recallable =
  ## getPublicAccessBlock
  ## <p/>
  result = call_599993.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_599981(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_599982, base: "/",
    url: url_GetPublicAccessBlock_599983, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_600009 = ref object of OpenApiRestCall_599368
proc url_DeletePublicAccessBlock_600011(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePublicAccessBlock_600010(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the block public access configuration for the specified account.
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the AWS account whose block public access configuration you want to delete.
  section = newJObject()
  var valid_600012 = header.getOrDefault("X-Amz-Date")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Date", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Security-Token")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Security-Token", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Content-Sha256", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Algorithm")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Algorithm", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Signature")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Signature", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-SignedHeaders", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Credential")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Credential", valid_600018
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_600019 = header.getOrDefault("x-amz-account-id")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = nil)
  if valid_600019 != nil:
    section.add "x-amz-account-id", valid_600019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600020: Call_DeletePublicAccessBlock_600009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the block public access configuration for the specified account.
  ## 
  let valid = call_600020.validator(path, query, header, formData, body)
  let scheme = call_600020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600020.url(scheme.get, call_600020.host, call_600020.base,
                         call_600020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600020, url, valid)

proc call*(call_600021: Call_DeletePublicAccessBlock_600009): Recallable =
  ## deletePublicAccessBlock
  ## Deletes the block public access configuration for the specified account.
  result = call_600021.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_600009(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_600010, base: "/",
    url: url_DeletePublicAccessBlock_600011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_600022 = ref object of OpenApiRestCall_599368
proc url_DescribeJob_600024(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJob_600023(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_600039 = path.getOrDefault("id")
  valid_600039 = validateParameter(valid_600039, JString, required = true,
                                 default = nil)
  if valid_600039 != nil:
    section.add "id", valid_600039
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_600040 = header.getOrDefault("X-Amz-Date")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Date", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Security-Token")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Security-Token", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Content-Sha256", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Algorithm")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Algorithm", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Signature")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Signature", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-SignedHeaders", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Credential")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Credential", valid_600046
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_600047 = header.getOrDefault("x-amz-account-id")
  valid_600047 = validateParameter(valid_600047, JString, required = true,
                                 default = nil)
  if valid_600047 != nil:
    section.add "x-amz-account-id", valid_600047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600048: Call_DescribeJob_600022; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  let valid = call_600048.validator(path, query, header, formData, body)
  let scheme = call_600048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600048.url(scheme.get, call_600048.host, call_600048.base,
                         call_600048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600048, url, valid)

proc call*(call_600049: Call_DescribeJob_600022; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   id: string (required)
  ##     : The ID for the job whose information you want to retrieve.
  var path_600050 = newJObject()
  add(path_600050, "id", newJString(id))
  result = call_600049.call(path_600050, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_600022(name: "describeJob",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3-control.amazonaws.com", route: "/v20180820/jobs/{id}#x-amz-account-id",
                                        validator: validate_DescribeJob_600023,
                                        base: "/", url: url_DescribeJob_600024,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_600051 = ref object of OpenApiRestCall_599368
proc url_UpdateJobPriority_600053(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/priority#x-amz-account-id&priority")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobPriority_600052(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing job's priority.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose priority you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_600054 = path.getOrDefault("id")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = nil)
  if valid_600054 != nil:
    section.add "id", valid_600054
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `priority` field"
  var valid_600055 = query.getOrDefault("priority")
  valid_600055 = validateParameter(valid_600055, JInt, required = true, default = nil)
  if valid_600055 != nil:
    section.add "priority", valid_600055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_600056 = header.getOrDefault("X-Amz-Date")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Date", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Security-Token")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Security-Token", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Content-Sha256", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Algorithm")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Algorithm", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Signature")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Signature", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-SignedHeaders", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Credential")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Credential", valid_600062
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_600063 = header.getOrDefault("x-amz-account-id")
  valid_600063 = validateParameter(valid_600063, JString, required = true,
                                 default = nil)
  if valid_600063 != nil:
    section.add "x-amz-account-id", valid_600063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600064: Call_UpdateJobPriority_600051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job's priority.
  ## 
  let valid = call_600064.validator(path, query, header, formData, body)
  let scheme = call_600064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600064.url(scheme.get, call_600064.host, call_600064.base,
                         call_600064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600064, url, valid)

proc call*(call_600065: Call_UpdateJobPriority_600051; id: string; priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
  ##     : The ID for the job whose priority you want to update.
  ##   priority: int (required)
  ##           : The priority you want to assign to this job.
  var path_600066 = newJObject()
  var query_600067 = newJObject()
  add(path_600066, "id", newJString(id))
  add(query_600067, "priority", newJInt(priority))
  result = call_600065.call(path_600066, query_600067, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_600051(name: "updateJobPriority",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_600052, base: "/",
    url: url_UpdateJobPriority_600053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_600068 = ref object of OpenApiRestCall_599368
proc url_UpdateJobStatus_600070(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/status#x-amz-account-id&requestedJobStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobStatus_600069(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the job whose status you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_600071 = path.getOrDefault("id")
  valid_600071 = validateParameter(valid_600071, JString, required = true,
                                 default = nil)
  if valid_600071 != nil:
    section.add "id", valid_600071
  result.add "path", section
  ## parameters in `query` object:
  ##   requestedJobStatus: JString (required)
  ##                     : The status that you want to move the specified job to.
  ##   statusUpdateReason: JString
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `requestedJobStatus` field"
  var valid_600085 = query.getOrDefault("requestedJobStatus")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = newJString("Cancelled"))
  if valid_600085 != nil:
    section.add "requestedJobStatus", valid_600085
  var valid_600086 = query.getOrDefault("statusUpdateReason")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "statusUpdateReason", valid_600086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_600087 = header.getOrDefault("X-Amz-Date")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Date", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Security-Token")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Security-Token", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Content-Sha256", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Algorithm")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Algorithm", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Signature")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Signature", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-SignedHeaders", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Credential")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Credential", valid_600093
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_600094 = header.getOrDefault("x-amz-account-id")
  valid_600094 = validateParameter(valid_600094, JString, required = true,
                                 default = nil)
  if valid_600094 != nil:
    section.add "x-amz-account-id", valid_600094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_UpdateJobStatus_600068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_UpdateJobStatus_600068; id: string;
          requestedJobStatus: string = "Cancelled"; statusUpdateReason: string = ""): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   requestedJobStatus: string (required)
  ##                     : The status that you want to move the specified job to.
  ##   id: string (required)
  ##     : The ID of the job whose status you want to update.
  ##   statusUpdateReason: string
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  var path_600097 = newJObject()
  var query_600098 = newJObject()
  add(query_600098, "requestedJobStatus", newJString(requestedJobStatus))
  add(path_600097, "id", newJString(id))
  add(query_600098, "statusUpdateReason", newJString(statusUpdateReason))
  result = call_600096.call(path_600097, query_600098, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_600068(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_600069, base: "/", url: url_UpdateJobStatus_600070,
    schemes: {Scheme.Https, Scheme.Http})
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
