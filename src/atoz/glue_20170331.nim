
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Glue
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Glue</fullname> <p>Defines the public endpoint for the AWS Glue service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glue/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glue.us-west-2.amazonaws.com",
                           "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "glue.eu-central-1.amazonaws.com",
                           "us-east-2": "glue.us-east-2.amazonaws.com",
                           "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glue.ap-south-1.amazonaws.com",
                           "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glue.us-west-1.amazonaws.com",
                           "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glue.eu-west-3.amazonaws.com",
                           "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glue.sa-east-1.amazonaws.com",
                           "eu-west-1": "glue.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "glue.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
      "us-west-2": "glue.us-west-2.amazonaws.com",
      "eu-west-2": "glue.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glue.eu-central-1.amazonaws.com",
      "us-east-2": "glue.us-east-2.amazonaws.com",
      "us-east-1": "glue.us-east-1.amazonaws.com",
      "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glue.ap-south-1.amazonaws.com",
      "eu-north-1": "glue.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
      "us-west-1": "glue.us-west-1.amazonaws.com",
      "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glue.eu-west-3.amazonaws.com",
      "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glue.sa-east-1.amazonaws.com",
      "eu-west-1": "glue.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glue"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_602803 = ref object of OpenApiRestCall_602466
proc url_BatchCreatePartition_602805(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchCreatePartition_602804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more partitions in a batch operation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_BatchCreatePartition_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_BatchCreatePartition_602803; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var batchCreatePartition* = Call_BatchCreatePartition_602803(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_602804, base: "/",
    url: url_BatchCreatePartition_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_603072 = ref object of OpenApiRestCall_602466
proc url_BatchDeleteConnection_603074(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteConnection_603073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a list of connection definitions from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_BatchDeleteConnection_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_BatchDeleteConnection_603072; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var batchDeleteConnection* = Call_BatchDeleteConnection_603072(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_603073, base: "/",
    url: url_BatchDeleteConnection_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_603087 = ref object of OpenApiRestCall_602466
proc url_BatchDeletePartition_603089(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePartition_603088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes one or more partitions in a batch operation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_BatchDeletePartition_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_BatchDeletePartition_603087; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var batchDeletePartition* = Call_BatchDeletePartition_603087(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_603088, base: "/",
    url: url_BatchDeletePartition_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_603102 = ref object of OpenApiRestCall_602466
proc url_BatchDeleteTable_603104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTable_603103(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_BatchDeleteTable_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_BatchDeleteTable_603102; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var batchDeleteTable* = Call_BatchDeleteTable_603102(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_603103, base: "/",
    url: url_BatchDeleteTable_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_603117 = ref object of OpenApiRestCall_602466
proc url_BatchDeleteTableVersion_603119(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTableVersion_603118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified batch of versions of a table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_BatchDeleteTableVersion_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_BatchDeleteTableVersion_603117; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_603117(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_603118, base: "/",
    url: url_BatchDeleteTableVersion_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_603132 = ref object of OpenApiRestCall_602466
proc url_BatchGetCrawlers_603134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetCrawlers_603133(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_BatchGetCrawlers_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_BatchGetCrawlers_603132; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var batchGetCrawlers* = Call_BatchGetCrawlers_603132(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_603133, base: "/",
    url: url_BatchGetCrawlers_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_603147 = ref object of OpenApiRestCall_602466
proc url_BatchGetDevEndpoints_603149(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDevEndpoints_603148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_BatchGetDevEndpoints_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_BatchGetDevEndpoints_603147; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_603147(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_603148, base: "/",
    url: url_BatchGetDevEndpoints_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_603162 = ref object of OpenApiRestCall_602466
proc url_BatchGetJobs_603164(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetJobs_603163(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_BatchGetJobs_603162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_BatchGetJobs_603162; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var batchGetJobs* = Call_BatchGetJobs_603162(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_603163, base: "/", url: url_BatchGetJobs_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_603177 = ref object of OpenApiRestCall_602466
proc url_BatchGetPartition_603179(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetPartition_603178(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves partitions in a batch request.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_BatchGetPartition_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_BatchGetPartition_603177; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var batchGetPartition* = Call_BatchGetPartition_603177(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_603178, base: "/",
    url: url_BatchGetPartition_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_603192 = ref object of OpenApiRestCall_602466
proc url_BatchGetTriggers_603194(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetTriggers_603193(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_BatchGetTriggers_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_BatchGetTriggers_603192; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var batchGetTriggers* = Call_BatchGetTriggers_603192(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_603193, base: "/",
    url: url_BatchGetTriggers_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_603207 = ref object of OpenApiRestCall_602466
proc url_BatchGetWorkflows_603209(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetWorkflows_603208(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_BatchGetWorkflows_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_BatchGetWorkflows_603207; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var batchGetWorkflows* = Call_BatchGetWorkflows_603207(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_603208, base: "/",
    url: url_BatchGetWorkflows_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_603222 = ref object of OpenApiRestCall_602466
proc url_BatchStopJobRun_603224(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchStopJobRun_603223(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Stops one or more job runs for a specified job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_BatchStopJobRun_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_BatchStopJobRun_603222; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var batchStopJobRun* = Call_BatchStopJobRun_603222(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_603223, base: "/", url: url_BatchStopJobRun_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_603237 = ref object of OpenApiRestCall_602466
proc url_CancelMLTaskRun_603239(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelMLTaskRun_603238(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_CancelMLTaskRun_603237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_CancelMLTaskRun_603237; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var cancelMLTaskRun* = Call_CancelMLTaskRun_603237(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_603238, base: "/", url: url_CancelMLTaskRun_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_603252 = ref object of OpenApiRestCall_602466
proc url_CreateClassifier_603254(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateClassifier_603253(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_CreateClassifier_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_CreateClassifier_603252; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var createClassifier* = Call_CreateClassifier_603252(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_603253, base: "/",
    url: url_CreateClassifier_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_603267 = ref object of OpenApiRestCall_602466
proc url_CreateConnection_603269(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnection_603268(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a connection definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_CreateConnection_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_CreateConnection_603267; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var createConnection* = Call_CreateConnection_603267(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_603268, base: "/",
    url: url_CreateConnection_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_603282 = ref object of OpenApiRestCall_602466
proc url_CreateCrawler_603284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCrawler_603283(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_CreateCrawler_603282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_CreateCrawler_603282; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var createCrawler* = Call_CreateCrawler_603282(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_603283, base: "/", url: url_CreateCrawler_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_603297 = ref object of OpenApiRestCall_602466
proc url_CreateDatabase_603299(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatabase_603298(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new database in a Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_CreateDatabase_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_CreateDatabase_603297; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var createDatabase* = Call_CreateDatabase_603297(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_603298, base: "/", url: url_CreateDatabase_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_603312 = ref object of OpenApiRestCall_602466
proc url_CreateDevEndpoint_603314(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDevEndpoint_603313(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new development endpoint.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_CreateDevEndpoint_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_CreateDevEndpoint_603312; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var createDevEndpoint* = Call_CreateDevEndpoint_603312(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_603313, base: "/",
    url: url_CreateDevEndpoint_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_603327 = ref object of OpenApiRestCall_602466
proc url_CreateJob_603329(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_603328(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_CreateJob_603327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_CreateJob_603327; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var createJob* = Call_CreateJob_603327(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_603328,
                                    base: "/", url: url_CreateJob_603329,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_603342 = ref object of OpenApiRestCall_602466
proc url_CreateMLTransform_603344(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMLTransform_603343(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_CreateMLTransform_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_CreateMLTransform_603342; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var createMLTransform* = Call_CreateMLTransform_603342(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_603343, base: "/",
    url: url_CreateMLTransform_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_603357 = ref object of OpenApiRestCall_602466
proc url_CreatePartition_603359(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePartition_603358(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_CreatePartition_603357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_CreatePartition_603357; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var createPartition* = Call_CreatePartition_603357(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_603358, base: "/", url: url_CreatePartition_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_603372 = ref object of OpenApiRestCall_602466
proc url_CreateScript_603374(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateScript_603373(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Transforms a directed acyclic graph (DAG) into code.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_CreateScript_603372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_CreateScript_603372; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var createScript* = Call_CreateScript_603372(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_603373, base: "/", url: url_CreateScript_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_603387 = ref object of OpenApiRestCall_602466
proc url_CreateSecurityConfiguration_603389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSecurityConfiguration_603388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_CreateSecurityConfiguration_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_CreateSecurityConfiguration_603387; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_603387(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_603388, base: "/",
    url: url_CreateSecurityConfiguration_603389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_603402 = ref object of OpenApiRestCall_602466
proc url_CreateTable_603404(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTable_603403(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new table definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_CreateTable_603402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_CreateTable_603402; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var createTable* = Call_CreateTable_603402(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_603403,
                                        base: "/", url: url_CreateTable_603404,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_603417 = ref object of OpenApiRestCall_602466
proc url_CreateTrigger_603419(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrigger_603418(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new trigger.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_CreateTrigger_603417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_CreateTrigger_603417; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_603431 = newJObject()
  if body != nil:
    body_603431 = body
  result = call_603430.call(nil, nil, nil, nil, body_603431)

var createTrigger* = Call_CreateTrigger_603417(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_603418, base: "/", url: url_CreateTrigger_603419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_603432 = ref object of OpenApiRestCall_602466
proc url_CreateUserDefinedFunction_603434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUserDefinedFunction_603433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new function definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603437 = header.getOrDefault("X-Amz-Target")
  valid_603437 = validateParameter(valid_603437, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_603437 != nil:
    section.add "X-Amz-Target", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_CreateUserDefinedFunction_603432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_CreateUserDefinedFunction_603432; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_603446 = newJObject()
  if body != nil:
    body_603446 = body
  result = call_603445.call(nil, nil, nil, nil, body_603446)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_603432(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_603433, base: "/",
    url: url_CreateUserDefinedFunction_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_603447 = ref object of OpenApiRestCall_602466
proc url_CreateWorkflow_603449(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkflow_603448(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603459: Call_CreateWorkflow_603447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_603459.validator(path, query, header, formData, body)
  let scheme = call_603459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603459.url(scheme.get, call_603459.host, call_603459.base,
                         call_603459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603459, url, valid)

proc call*(call_603460: Call_CreateWorkflow_603447; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_603461 = newJObject()
  if body != nil:
    body_603461 = body
  result = call_603460.call(nil, nil, nil, nil, body_603461)

var createWorkflow* = Call_CreateWorkflow_603447(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_603448, base: "/", url: url_CreateWorkflow_603449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_603462 = ref object of OpenApiRestCall_602466
proc url_DeleteClassifier_603464(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteClassifier_603463(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes a classifier from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603465 = header.getOrDefault("X-Amz-Date")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Date", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_DeleteClassifier_603462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_DeleteClassifier_603462; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_603476 = newJObject()
  if body != nil:
    body_603476 = body
  result = call_603475.call(nil, nil, nil, nil, body_603476)

var deleteClassifier* = Call_DeleteClassifier_603462(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_603463, base: "/",
    url: url_DeleteClassifier_603464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_603477 = ref object of OpenApiRestCall_602466
proc url_DeleteConnection_603479(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConnection_603478(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a connection from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603482 = header.getOrDefault("X-Amz-Target")
  valid_603482 = validateParameter(valid_603482, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_603482 != nil:
    section.add "X-Amz-Target", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_DeleteConnection_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_DeleteConnection_603477; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_603491 = newJObject()
  if body != nil:
    body_603491 = body
  result = call_603490.call(nil, nil, nil, nil, body_603491)

var deleteConnection* = Call_DeleteConnection_603477(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_603478, base: "/",
    url: url_DeleteConnection_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_603492 = ref object of OpenApiRestCall_602466
proc url_DeleteCrawler_603494(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCrawler_603493(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603497 = header.getOrDefault("X-Amz-Target")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_603497 != nil:
    section.add "X-Amz-Target", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_DeleteCrawler_603492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_DeleteCrawler_603492; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_603506 = newJObject()
  if body != nil:
    body_603506 = body
  result = call_603505.call(nil, nil, nil, nil, body_603506)

var deleteCrawler* = Call_DeleteCrawler_603492(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_603493, base: "/", url: url_DeleteCrawler_603494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_603507 = ref object of OpenApiRestCall_602466
proc url_DeleteDatabase_603509(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDatabase_603508(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603510 = header.getOrDefault("X-Amz-Date")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Date", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603512 = header.getOrDefault("X-Amz-Target")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_603512 != nil:
    section.add "X-Amz-Target", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_DeleteDatabase_603507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_DeleteDatabase_603507; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_603521 = newJObject()
  if body != nil:
    body_603521 = body
  result = call_603520.call(nil, nil, nil, nil, body_603521)

var deleteDatabase* = Call_DeleteDatabase_603507(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_603508, base: "/", url: url_DeleteDatabase_603509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_603522 = ref object of OpenApiRestCall_602466
proc url_DeleteDevEndpoint_603524(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevEndpoint_603523(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a specified development endpoint.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603525 = header.getOrDefault("X-Amz-Date")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Date", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Security-Token")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Security-Token", valid_603526
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603527 = header.getOrDefault("X-Amz-Target")
  valid_603527 = validateParameter(valid_603527, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_603527 != nil:
    section.add "X-Amz-Target", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603534: Call_DeleteDevEndpoint_603522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_603534.validator(path, query, header, formData, body)
  let scheme = call_603534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603534.url(scheme.get, call_603534.host, call_603534.base,
                         call_603534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603534, url, valid)

proc call*(call_603535: Call_DeleteDevEndpoint_603522; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_603536 = newJObject()
  if body != nil:
    body_603536 = body
  result = call_603535.call(nil, nil, nil, nil, body_603536)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_603522(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_603523, base: "/",
    url: url_DeleteDevEndpoint_603524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_603537 = ref object of OpenApiRestCall_602466
proc url_DeleteJob_603539(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteJob_603538(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603540 = header.getOrDefault("X-Amz-Date")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Date", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Security-Token")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Security-Token", valid_603541
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603542 = header.getOrDefault("X-Amz-Target")
  valid_603542 = validateParameter(valid_603542, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_603542 != nil:
    section.add "X-Amz-Target", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_DeleteJob_603537; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_DeleteJob_603537; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_603551 = newJObject()
  if body != nil:
    body_603551 = body
  result = call_603550.call(nil, nil, nil, nil, body_603551)

var deleteJob* = Call_DeleteJob_603537(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_603538,
                                    base: "/", url: url_DeleteJob_603539,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_603552 = ref object of OpenApiRestCall_602466
proc url_DeleteMLTransform_603554(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMLTransform_603553(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603555 = header.getOrDefault("X-Amz-Date")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Date", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Security-Token")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Security-Token", valid_603556
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603557 = header.getOrDefault("X-Amz-Target")
  valid_603557 = validateParameter(valid_603557, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_603557 != nil:
    section.add "X-Amz-Target", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Content-Sha256", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Signature")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Signature", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603564: Call_DeleteMLTransform_603552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_603564.validator(path, query, header, formData, body)
  let scheme = call_603564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603564.url(scheme.get, call_603564.host, call_603564.base,
                         call_603564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603564, url, valid)

proc call*(call_603565: Call_DeleteMLTransform_603552; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_603566 = newJObject()
  if body != nil:
    body_603566 = body
  result = call_603565.call(nil, nil, nil, nil, body_603566)

var deleteMLTransform* = Call_DeleteMLTransform_603552(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_603553, base: "/",
    url: url_DeleteMLTransform_603554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_603567 = ref object of OpenApiRestCall_602466
proc url_DeletePartition_603569(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePartition_603568(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a specified partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603570 = header.getOrDefault("X-Amz-Date")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Date", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Security-Token")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Security-Token", valid_603571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603572 = header.getOrDefault("X-Amz-Target")
  valid_603572 = validateParameter(valid_603572, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_603572 != nil:
    section.add "X-Amz-Target", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Content-Sha256", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Algorithm")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Algorithm", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Signature")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Signature", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_DeletePartition_603567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_DeletePartition_603567; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_603581 = newJObject()
  if body != nil:
    body_603581 = body
  result = call_603580.call(nil, nil, nil, nil, body_603581)

var deletePartition* = Call_DeletePartition_603567(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_603568, base: "/", url: url_DeletePartition_603569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_603582 = ref object of OpenApiRestCall_602466
proc url_DeleteResourcePolicy_603584(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourcePolicy_603583(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603585 = header.getOrDefault("X-Amz-Date")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Date", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Security-Token")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Security-Token", valid_603586
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603587 = header.getOrDefault("X-Amz-Target")
  valid_603587 = validateParameter(valid_603587, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_603587 != nil:
    section.add "X-Amz-Target", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Content-Sha256", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Algorithm")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Algorithm", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Signature")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Signature", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-SignedHeaders", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Credential")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Credential", valid_603592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603594: Call_DeleteResourcePolicy_603582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_603594.validator(path, query, header, formData, body)
  let scheme = call_603594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603594.url(scheme.get, call_603594.host, call_603594.base,
                         call_603594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603594, url, valid)

proc call*(call_603595: Call_DeleteResourcePolicy_603582; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_603596 = newJObject()
  if body != nil:
    body_603596 = body
  result = call_603595.call(nil, nil, nil, nil, body_603596)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_603582(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_603583, base: "/",
    url: url_DeleteResourcePolicy_603584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_603597 = ref object of OpenApiRestCall_602466
proc url_DeleteSecurityConfiguration_603599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSecurityConfiguration_603598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified security configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603602 = header.getOrDefault("X-Amz-Target")
  valid_603602 = validateParameter(valid_603602, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_603602 != nil:
    section.add "X-Amz-Target", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Content-Sha256", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Algorithm")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Algorithm", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Signature")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Signature", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Credential")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Credential", valid_603607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603609: Call_DeleteSecurityConfiguration_603597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_603609.validator(path, query, header, formData, body)
  let scheme = call_603609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603609.url(scheme.get, call_603609.host, call_603609.base,
                         call_603609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603609, url, valid)

proc call*(call_603610: Call_DeleteSecurityConfiguration_603597; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_603611 = newJObject()
  if body != nil:
    body_603611 = body
  result = call_603610.call(nil, nil, nil, nil, body_603611)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_603597(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_603598, base: "/",
    url: url_DeleteSecurityConfiguration_603599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_603612 = ref object of OpenApiRestCall_602466
proc url_DeleteTable_603614(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTable_603613(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603617 = header.getOrDefault("X-Amz-Target")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_603617 != nil:
    section.add "X-Amz-Target", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Content-Sha256", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Algorithm")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Algorithm", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Signature")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Signature", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Credential")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Credential", valid_603622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_DeleteTable_603612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_DeleteTable_603612; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_603626 = newJObject()
  if body != nil:
    body_603626 = body
  result = call_603625.call(nil, nil, nil, nil, body_603626)

var deleteTable* = Call_DeleteTable_603612(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_603613,
                                        base: "/", url: url_DeleteTable_603614,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_603627 = ref object of OpenApiRestCall_602466
proc url_DeleteTableVersion_603629(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTableVersion_603628(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a specified version of a table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603632 = header.getOrDefault("X-Amz-Target")
  valid_603632 = validateParameter(valid_603632, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_603632 != nil:
    section.add "X-Amz-Target", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Algorithm")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Algorithm", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_DeleteTableVersion_603627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_DeleteTableVersion_603627; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_603641 = newJObject()
  if body != nil:
    body_603641 = body
  result = call_603640.call(nil, nil, nil, nil, body_603641)

var deleteTableVersion* = Call_DeleteTableVersion_603627(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_603628, base: "/",
    url: url_DeleteTableVersion_603629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_603642 = ref object of OpenApiRestCall_602466
proc url_DeleteTrigger_603644(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTrigger_603643(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603645 = header.getOrDefault("X-Amz-Date")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Date", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Security-Token")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Security-Token", valid_603646
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603647 = header.getOrDefault("X-Amz-Target")
  valid_603647 = validateParameter(valid_603647, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_603647 != nil:
    section.add "X-Amz-Target", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Content-Sha256", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Algorithm")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Algorithm", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Signature")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Signature", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Credential")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Credential", valid_603652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603654: Call_DeleteTrigger_603642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_603654.validator(path, query, header, formData, body)
  let scheme = call_603654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603654.url(scheme.get, call_603654.host, call_603654.base,
                         call_603654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603654, url, valid)

proc call*(call_603655: Call_DeleteTrigger_603642; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_603656 = newJObject()
  if body != nil:
    body_603656 = body
  result = call_603655.call(nil, nil, nil, nil, body_603656)

var deleteTrigger* = Call_DeleteTrigger_603642(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_603643, base: "/", url: url_DeleteTrigger_603644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_603657 = ref object of OpenApiRestCall_602466
proc url_DeleteUserDefinedFunction_603659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUserDefinedFunction_603658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing function definition from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603660 = header.getOrDefault("X-Amz-Date")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Date", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Security-Token")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Security-Token", valid_603661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603662 = header.getOrDefault("X-Amz-Target")
  valid_603662 = validateParameter(valid_603662, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_603662 != nil:
    section.add "X-Amz-Target", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Content-Sha256", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Algorithm")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Algorithm", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Signature")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Signature", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-SignedHeaders", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Credential")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Credential", valid_603667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603669: Call_DeleteUserDefinedFunction_603657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_603669.validator(path, query, header, formData, body)
  let scheme = call_603669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603669.url(scheme.get, call_603669.host, call_603669.base,
                         call_603669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603669, url, valid)

proc call*(call_603670: Call_DeleteUserDefinedFunction_603657; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_603671 = newJObject()
  if body != nil:
    body_603671 = body
  result = call_603670.call(nil, nil, nil, nil, body_603671)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_603657(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_603658, base: "/",
    url: url_DeleteUserDefinedFunction_603659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_603672 = ref object of OpenApiRestCall_602466
proc url_DeleteWorkflow_603674(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkflow_603673(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603675 = header.getOrDefault("X-Amz-Date")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Date", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Security-Token")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Security-Token", valid_603676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603677 = header.getOrDefault("X-Amz-Target")
  valid_603677 = validateParameter(valid_603677, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_603677 != nil:
    section.add "X-Amz-Target", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Content-Sha256", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Algorithm")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Algorithm", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Signature")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Signature", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-SignedHeaders", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Credential")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Credential", valid_603682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603684: Call_DeleteWorkflow_603672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_603684.validator(path, query, header, formData, body)
  let scheme = call_603684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603684.url(scheme.get, call_603684.host, call_603684.base,
                         call_603684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603684, url, valid)

proc call*(call_603685: Call_DeleteWorkflow_603672; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_603686 = newJObject()
  if body != nil:
    body_603686 = body
  result = call_603685.call(nil, nil, nil, nil, body_603686)

var deleteWorkflow* = Call_DeleteWorkflow_603672(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_603673, base: "/", url: url_DeleteWorkflow_603674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_603687 = ref object of OpenApiRestCall_602466
proc url_GetCatalogImportStatus_603689(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCatalogImportStatus_603688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the status of a migration operation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603690 = header.getOrDefault("X-Amz-Date")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Date", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603692 = header.getOrDefault("X-Amz-Target")
  valid_603692 = validateParameter(valid_603692, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_603692 != nil:
    section.add "X-Amz-Target", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Content-Sha256", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Algorithm")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Algorithm", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Signature")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Signature", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Credential")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Credential", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603699: Call_GetCatalogImportStatus_603687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_603699.validator(path, query, header, formData, body)
  let scheme = call_603699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603699.url(scheme.get, call_603699.host, call_603699.base,
                         call_603699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603699, url, valid)

proc call*(call_603700: Call_GetCatalogImportStatus_603687; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_603701 = newJObject()
  if body != nil:
    body_603701 = body
  result = call_603700.call(nil, nil, nil, nil, body_603701)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_603687(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_603688, base: "/",
    url: url_GetCatalogImportStatus_603689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_603702 = ref object of OpenApiRestCall_602466
proc url_GetClassifier_603704(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifier_603703(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a classifier by name.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603705 = header.getOrDefault("X-Amz-Date")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Date", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Security-Token")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Security-Token", valid_603706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603707 = header.getOrDefault("X-Amz-Target")
  valid_603707 = validateParameter(valid_603707, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_603707 != nil:
    section.add "X-Amz-Target", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Content-Sha256", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Algorithm")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Algorithm", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603714: Call_GetClassifier_603702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_603714.validator(path, query, header, formData, body)
  let scheme = call_603714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603714.url(scheme.get, call_603714.host, call_603714.base,
                         call_603714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603714, url, valid)

proc call*(call_603715: Call_GetClassifier_603702; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_603716 = newJObject()
  if body != nil:
    body_603716 = body
  result = call_603715.call(nil, nil, nil, nil, body_603716)

var getClassifier* = Call_GetClassifier_603702(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_603703, base: "/", url: url_GetClassifier_603704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_603717 = ref object of OpenApiRestCall_602466
proc url_GetClassifiers_603719(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifiers_603718(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603720 = query.getOrDefault("NextToken")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "NextToken", valid_603720
  var valid_603721 = query.getOrDefault("MaxResults")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "MaxResults", valid_603721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603722 = header.getOrDefault("X-Amz-Date")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Date", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Security-Token")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Security-Token", valid_603723
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603724 = header.getOrDefault("X-Amz-Target")
  valid_603724 = validateParameter(valid_603724, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_603724 != nil:
    section.add "X-Amz-Target", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Content-Sha256", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Algorithm")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Algorithm", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Signature")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Signature", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-SignedHeaders", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Credential")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Credential", valid_603729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603731: Call_GetClassifiers_603717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_GetClassifiers_603717; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603733 = newJObject()
  var body_603734 = newJObject()
  add(query_603733, "NextToken", newJString(NextToken))
  if body != nil:
    body_603734 = body
  add(query_603733, "MaxResults", newJString(MaxResults))
  result = call_603732.call(nil, query_603733, nil, nil, body_603734)

var getClassifiers* = Call_GetClassifiers_603717(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_603718, base: "/", url: url_GetClassifiers_603719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_603736 = ref object of OpenApiRestCall_602466
proc url_GetConnection_603738(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnection_603737(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a connection definition from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603741 = header.getOrDefault("X-Amz-Target")
  valid_603741 = validateParameter(valid_603741, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_603741 != nil:
    section.add "X-Amz-Target", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Content-Sha256", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Algorithm")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Algorithm", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Signature")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Signature", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-SignedHeaders", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Credential")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Credential", valid_603746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603748: Call_GetConnection_603736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_603748.validator(path, query, header, formData, body)
  let scheme = call_603748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603748.url(scheme.get, call_603748.host, call_603748.base,
                         call_603748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603748, url, valid)

proc call*(call_603749: Call_GetConnection_603736; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_603750 = newJObject()
  if body != nil:
    body_603750 = body
  result = call_603749.call(nil, nil, nil, nil, body_603750)

var getConnection* = Call_GetConnection_603736(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_603737, base: "/", url: url_GetConnection_603738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_603751 = ref object of OpenApiRestCall_602466
proc url_GetConnections_603753(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnections_603752(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603754 = query.getOrDefault("NextToken")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "NextToken", valid_603754
  var valid_603755 = query.getOrDefault("MaxResults")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "MaxResults", valid_603755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603756 = header.getOrDefault("X-Amz-Date")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Date", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Security-Token")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Security-Token", valid_603757
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603758 = header.getOrDefault("X-Amz-Target")
  valid_603758 = validateParameter(valid_603758, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_603758 != nil:
    section.add "X-Amz-Target", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Content-Sha256", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Algorithm")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Algorithm", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Signature")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Signature", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-SignedHeaders", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Credential")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Credential", valid_603763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603765: Call_GetConnections_603751; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_603765.validator(path, query, header, formData, body)
  let scheme = call_603765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603765.url(scheme.get, call_603765.host, call_603765.base,
                         call_603765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603765, url, valid)

proc call*(call_603766: Call_GetConnections_603751; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603767 = newJObject()
  var body_603768 = newJObject()
  add(query_603767, "NextToken", newJString(NextToken))
  if body != nil:
    body_603768 = body
  add(query_603767, "MaxResults", newJString(MaxResults))
  result = call_603766.call(nil, query_603767, nil, nil, body_603768)

var getConnections* = Call_GetConnections_603751(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_603752, base: "/", url: url_GetConnections_603753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_603769 = ref object of OpenApiRestCall_602466
proc url_GetCrawler_603771(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawler_603770(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for a specified crawler.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603772 = header.getOrDefault("X-Amz-Date")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Date", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Security-Token")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Security-Token", valid_603773
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603774 = header.getOrDefault("X-Amz-Target")
  valid_603774 = validateParameter(valid_603774, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_603774 != nil:
    section.add "X-Amz-Target", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Content-Sha256", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Algorithm")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Algorithm", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Signature")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Signature", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-SignedHeaders", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Credential")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Credential", valid_603779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603781: Call_GetCrawler_603769; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_603781.validator(path, query, header, formData, body)
  let scheme = call_603781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603781.url(scheme.get, call_603781.host, call_603781.base,
                         call_603781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603781, url, valid)

proc call*(call_603782: Call_GetCrawler_603769; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_603783 = newJObject()
  if body != nil:
    body_603783 = body
  result = call_603782.call(nil, nil, nil, nil, body_603783)

var getCrawler* = Call_GetCrawler_603769(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_603770,
                                      base: "/", url: url_GetCrawler_603771,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_603784 = ref object of OpenApiRestCall_602466
proc url_GetCrawlerMetrics_603786(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlerMetrics_603785(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves metrics about specified crawlers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603787 = query.getOrDefault("NextToken")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "NextToken", valid_603787
  var valid_603788 = query.getOrDefault("MaxResults")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "MaxResults", valid_603788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603789 = header.getOrDefault("X-Amz-Date")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Date", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Security-Token")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Security-Token", valid_603790
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603791 = header.getOrDefault("X-Amz-Target")
  valid_603791 = validateParameter(valid_603791, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_603791 != nil:
    section.add "X-Amz-Target", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Content-Sha256", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Algorithm")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Algorithm", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Signature")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Signature", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-SignedHeaders", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Credential")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Credential", valid_603796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603798: Call_GetCrawlerMetrics_603784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_603798.validator(path, query, header, formData, body)
  let scheme = call_603798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603798.url(scheme.get, call_603798.host, call_603798.base,
                         call_603798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603798, url, valid)

proc call*(call_603799: Call_GetCrawlerMetrics_603784; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603800 = newJObject()
  var body_603801 = newJObject()
  add(query_603800, "NextToken", newJString(NextToken))
  if body != nil:
    body_603801 = body
  add(query_603800, "MaxResults", newJString(MaxResults))
  result = call_603799.call(nil, query_603800, nil, nil, body_603801)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_603784(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_603785, base: "/",
    url: url_GetCrawlerMetrics_603786, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_603802 = ref object of OpenApiRestCall_602466
proc url_GetCrawlers_603804(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlers_603803(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603805 = query.getOrDefault("NextToken")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "NextToken", valid_603805
  var valid_603806 = query.getOrDefault("MaxResults")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "MaxResults", valid_603806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603807 = header.getOrDefault("X-Amz-Date")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Date", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Security-Token")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Security-Token", valid_603808
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603809 = header.getOrDefault("X-Amz-Target")
  valid_603809 = validateParameter(valid_603809, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_603809 != nil:
    section.add "X-Amz-Target", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Content-Sha256", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Algorithm")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Algorithm", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-Signature")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Signature", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-SignedHeaders", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Credential")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Credential", valid_603814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603816: Call_GetCrawlers_603802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_603816.validator(path, query, header, formData, body)
  let scheme = call_603816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603816.url(scheme.get, call_603816.host, call_603816.base,
                         call_603816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603816, url, valid)

proc call*(call_603817: Call_GetCrawlers_603802; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603818 = newJObject()
  var body_603819 = newJObject()
  add(query_603818, "NextToken", newJString(NextToken))
  if body != nil:
    body_603819 = body
  add(query_603818, "MaxResults", newJString(MaxResults))
  result = call_603817.call(nil, query_603818, nil, nil, body_603819)

var getCrawlers* = Call_GetCrawlers_603802(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_603803,
                                        base: "/", url: url_GetCrawlers_603804,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_603820 = ref object of OpenApiRestCall_602466
proc url_GetDataCatalogEncryptionSettings_603822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_603821(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the security configuration for a specified catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603823 = header.getOrDefault("X-Amz-Date")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Date", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Security-Token")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Security-Token", valid_603824
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603825 = header.getOrDefault("X-Amz-Target")
  valid_603825 = validateParameter(valid_603825, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_603825 != nil:
    section.add "X-Amz-Target", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Content-Sha256", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Algorithm")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Algorithm", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Signature")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Signature", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-SignedHeaders", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Credential")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Credential", valid_603830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603832: Call_GetDataCatalogEncryptionSettings_603820;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_603832.validator(path, query, header, formData, body)
  let scheme = call_603832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603832.url(scheme.get, call_603832.host, call_603832.base,
                         call_603832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603832, url, valid)

proc call*(call_603833: Call_GetDataCatalogEncryptionSettings_603820;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_603834 = newJObject()
  if body != nil:
    body_603834 = body
  result = call_603833.call(nil, nil, nil, nil, body_603834)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_603820(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_603821, base: "/",
    url: url_GetDataCatalogEncryptionSettings_603822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_603835 = ref object of OpenApiRestCall_602466
proc url_GetDatabase_603837(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabase_603836(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a specified database.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603838 = header.getOrDefault("X-Amz-Date")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Date", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Security-Token")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Security-Token", valid_603839
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603840 = header.getOrDefault("X-Amz-Target")
  valid_603840 = validateParameter(valid_603840, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_603840 != nil:
    section.add "X-Amz-Target", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Content-Sha256", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Algorithm")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Algorithm", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Signature")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Signature", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-SignedHeaders", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Credential")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Credential", valid_603845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603847: Call_GetDatabase_603835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_603847.validator(path, query, header, formData, body)
  let scheme = call_603847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603847.url(scheme.get, call_603847.host, call_603847.base,
                         call_603847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603847, url, valid)

proc call*(call_603848: Call_GetDatabase_603835; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_603849 = newJObject()
  if body != nil:
    body_603849 = body
  result = call_603848.call(nil, nil, nil, nil, body_603849)

var getDatabase* = Call_GetDatabase_603835(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_603836,
                                        base: "/", url: url_GetDatabase_603837,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_603850 = ref object of OpenApiRestCall_602466
proc url_GetDatabases_603852(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabases_603851(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603853 = query.getOrDefault("NextToken")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "NextToken", valid_603853
  var valid_603854 = query.getOrDefault("MaxResults")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "MaxResults", valid_603854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603855 = header.getOrDefault("X-Amz-Date")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Date", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Security-Token")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Security-Token", valid_603856
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603857 = header.getOrDefault("X-Amz-Target")
  valid_603857 = validateParameter(valid_603857, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_603857 != nil:
    section.add "X-Amz-Target", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Content-Sha256", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Algorithm")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Algorithm", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Signature")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Signature", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Credential")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Credential", valid_603862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603864: Call_GetDatabases_603850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_603864.validator(path, query, header, formData, body)
  let scheme = call_603864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603864.url(scheme.get, call_603864.host, call_603864.base,
                         call_603864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603864, url, valid)

proc call*(call_603865: Call_GetDatabases_603850; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603866 = newJObject()
  var body_603867 = newJObject()
  add(query_603866, "NextToken", newJString(NextToken))
  if body != nil:
    body_603867 = body
  add(query_603866, "MaxResults", newJString(MaxResults))
  result = call_603865.call(nil, query_603866, nil, nil, body_603867)

var getDatabases* = Call_GetDatabases_603850(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_603851, base: "/", url: url_GetDatabases_603852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_603868 = ref object of OpenApiRestCall_602466
proc url_GetDataflowGraph_603870(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataflowGraph_603869(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603871 = header.getOrDefault("X-Amz-Date")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Date", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Security-Token")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Security-Token", valid_603872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603873 = header.getOrDefault("X-Amz-Target")
  valid_603873 = validateParameter(valid_603873, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_603873 != nil:
    section.add "X-Amz-Target", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Content-Sha256", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Algorithm")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Algorithm", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Signature")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Signature", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-SignedHeaders", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Credential")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Credential", valid_603878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603880: Call_GetDataflowGraph_603868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_603880.validator(path, query, header, formData, body)
  let scheme = call_603880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603880.url(scheme.get, call_603880.host, call_603880.base,
                         call_603880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603880, url, valid)

proc call*(call_603881: Call_GetDataflowGraph_603868; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_603882 = newJObject()
  if body != nil:
    body_603882 = body
  result = call_603881.call(nil, nil, nil, nil, body_603882)

var getDataflowGraph* = Call_GetDataflowGraph_603868(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_603869, base: "/",
    url: url_GetDataflowGraph_603870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_603883 = ref object of OpenApiRestCall_602466
proc url_GetDevEndpoint_603885(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoint_603884(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603886 = header.getOrDefault("X-Amz-Date")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Date", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Security-Token")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Security-Token", valid_603887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603888 = header.getOrDefault("X-Amz-Target")
  valid_603888 = validateParameter(valid_603888, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_603888 != nil:
    section.add "X-Amz-Target", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Content-Sha256", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Algorithm")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Algorithm", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Signature")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Signature", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-SignedHeaders", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Credential")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Credential", valid_603893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603895: Call_GetDevEndpoint_603883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_603895.validator(path, query, header, formData, body)
  let scheme = call_603895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603895.url(scheme.get, call_603895.host, call_603895.base,
                         call_603895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603895, url, valid)

proc call*(call_603896: Call_GetDevEndpoint_603883; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_603897 = newJObject()
  if body != nil:
    body_603897 = body
  result = call_603896.call(nil, nil, nil, nil, body_603897)

var getDevEndpoint* = Call_GetDevEndpoint_603883(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_603884, base: "/", url: url_GetDevEndpoint_603885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_603898 = ref object of OpenApiRestCall_602466
proc url_GetDevEndpoints_603900(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoints_603899(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603901 = query.getOrDefault("NextToken")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "NextToken", valid_603901
  var valid_603902 = query.getOrDefault("MaxResults")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "MaxResults", valid_603902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603903 = header.getOrDefault("X-Amz-Date")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Date", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Security-Token")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Security-Token", valid_603904
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603905 = header.getOrDefault("X-Amz-Target")
  valid_603905 = validateParameter(valid_603905, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_603905 != nil:
    section.add "X-Amz-Target", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Algorithm")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Algorithm", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Signature")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Signature", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-SignedHeaders", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603912: Call_GetDevEndpoints_603898; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_603912.validator(path, query, header, formData, body)
  let scheme = call_603912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603912.url(scheme.get, call_603912.host, call_603912.base,
                         call_603912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603912, url, valid)

proc call*(call_603913: Call_GetDevEndpoints_603898; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603914 = newJObject()
  var body_603915 = newJObject()
  add(query_603914, "NextToken", newJString(NextToken))
  if body != nil:
    body_603915 = body
  add(query_603914, "MaxResults", newJString(MaxResults))
  result = call_603913.call(nil, query_603914, nil, nil, body_603915)

var getDevEndpoints* = Call_GetDevEndpoints_603898(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_603899, base: "/", url: url_GetDevEndpoints_603900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_603916 = ref object of OpenApiRestCall_602466
proc url_GetJob_603918(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJob_603917(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an existing job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603919 = header.getOrDefault("X-Amz-Date")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Date", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Security-Token")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Security-Token", valid_603920
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603921 = header.getOrDefault("X-Amz-Target")
  valid_603921 = validateParameter(valid_603921, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_603921 != nil:
    section.add "X-Amz-Target", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Content-Sha256", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Algorithm")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Algorithm", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Signature")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Signature", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-SignedHeaders", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Credential")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Credential", valid_603926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603928: Call_GetJob_603916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_603928.validator(path, query, header, formData, body)
  let scheme = call_603928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603928.url(scheme.get, call_603928.host, call_603928.base,
                         call_603928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603928, url, valid)

proc call*(call_603929: Call_GetJob_603916; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_603930 = newJObject()
  if body != nil:
    body_603930 = body
  result = call_603929.call(nil, nil, nil, nil, body_603930)

var getJob* = Call_GetJob_603916(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_603917, base: "/",
                              url: url_GetJob_603918,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_603931 = ref object of OpenApiRestCall_602466
proc url_GetJobBookmark_603933(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobBookmark_603932(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information on a job bookmark entry.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603934 = header.getOrDefault("X-Amz-Date")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Date", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Security-Token")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Security-Token", valid_603935
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603936 = header.getOrDefault("X-Amz-Target")
  valid_603936 = validateParameter(valid_603936, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_603936 != nil:
    section.add "X-Amz-Target", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Content-Sha256", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Algorithm")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Algorithm", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Signature")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Signature", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-SignedHeaders", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Credential")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Credential", valid_603941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603943: Call_GetJobBookmark_603931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_603943.validator(path, query, header, formData, body)
  let scheme = call_603943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603943.url(scheme.get, call_603943.host, call_603943.base,
                         call_603943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603943, url, valid)

proc call*(call_603944: Call_GetJobBookmark_603931; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_603945 = newJObject()
  if body != nil:
    body_603945 = body
  result = call_603944.call(nil, nil, nil, nil, body_603945)

var getJobBookmark* = Call_GetJobBookmark_603931(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_603932, base: "/", url: url_GetJobBookmark_603933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_603946 = ref object of OpenApiRestCall_602466
proc url_GetJobRun_603948(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRun_603947(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given job run.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603949 = header.getOrDefault("X-Amz-Date")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Date", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Security-Token")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Security-Token", valid_603950
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603951 = header.getOrDefault("X-Amz-Target")
  valid_603951 = validateParameter(valid_603951, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_603951 != nil:
    section.add "X-Amz-Target", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Content-Sha256", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Algorithm")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Algorithm", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Signature")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Signature", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-SignedHeaders", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Credential")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Credential", valid_603956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603958: Call_GetJobRun_603946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_603958.validator(path, query, header, formData, body)
  let scheme = call_603958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603958.url(scheme.get, call_603958.host, call_603958.base,
                         call_603958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603958, url, valid)

proc call*(call_603959: Call_GetJobRun_603946; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_603960 = newJObject()
  if body != nil:
    body_603960 = body
  result = call_603959.call(nil, nil, nil, nil, body_603960)

var getJobRun* = Call_GetJobRun_603946(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_603947,
                                    base: "/", url: url_GetJobRun_603948,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_603961 = ref object of OpenApiRestCall_602466
proc url_GetJobRuns_603963(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRuns_603962(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603964 = query.getOrDefault("NextToken")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "NextToken", valid_603964
  var valid_603965 = query.getOrDefault("MaxResults")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "MaxResults", valid_603965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603966 = header.getOrDefault("X-Amz-Date")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "X-Amz-Date", valid_603966
  var valid_603967 = header.getOrDefault("X-Amz-Security-Token")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Security-Token", valid_603967
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603968 = header.getOrDefault("X-Amz-Target")
  valid_603968 = validateParameter(valid_603968, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_603968 != nil:
    section.add "X-Amz-Target", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Content-Sha256", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Algorithm")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Algorithm", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Signature")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Signature", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-SignedHeaders", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Credential")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Credential", valid_603973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603975: Call_GetJobRuns_603961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_603975.validator(path, query, header, formData, body)
  let scheme = call_603975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603975.url(scheme.get, call_603975.host, call_603975.base,
                         call_603975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603975, url, valid)

proc call*(call_603976: Call_GetJobRuns_603961; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603977 = newJObject()
  var body_603978 = newJObject()
  add(query_603977, "NextToken", newJString(NextToken))
  if body != nil:
    body_603978 = body
  add(query_603977, "MaxResults", newJString(MaxResults))
  result = call_603976.call(nil, query_603977, nil, nil, body_603978)

var getJobRuns* = Call_GetJobRuns_603961(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_603962,
                                      base: "/", url: url_GetJobRuns_603963,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_603979 = ref object of OpenApiRestCall_602466
proc url_GetJobs_603981(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobs_603980(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all current job definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603982 = query.getOrDefault("NextToken")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "NextToken", valid_603982
  var valid_603983 = query.getOrDefault("MaxResults")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "MaxResults", valid_603983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603984 = header.getOrDefault("X-Amz-Date")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Date", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Security-Token")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Security-Token", valid_603985
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603986 = header.getOrDefault("X-Amz-Target")
  valid_603986 = validateParameter(valid_603986, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_603986 != nil:
    section.add "X-Amz-Target", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Content-Sha256", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Algorithm")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Algorithm", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Signature")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Signature", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-SignedHeaders", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Credential")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Credential", valid_603991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603993: Call_GetJobs_603979; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_603993.validator(path, query, header, formData, body)
  let scheme = call_603993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603993.url(scheme.get, call_603993.host, call_603993.base,
                         call_603993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603993, url, valid)

proc call*(call_603994: Call_GetJobs_603979; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603995 = newJObject()
  var body_603996 = newJObject()
  add(query_603995, "NextToken", newJString(NextToken))
  if body != nil:
    body_603996 = body
  add(query_603995, "MaxResults", newJString(MaxResults))
  result = call_603994.call(nil, query_603995, nil, nil, body_603996)

var getJobs* = Call_GetJobs_603979(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_603980, base: "/",
                                url: url_GetJobs_603981,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_603997 = ref object of OpenApiRestCall_602466
proc url_GetMLTaskRun_603999(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRun_603998(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604000 = header.getOrDefault("X-Amz-Date")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Date", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Security-Token")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Security-Token", valid_604001
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604002 = header.getOrDefault("X-Amz-Target")
  valid_604002 = validateParameter(valid_604002, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_604002 != nil:
    section.add "X-Amz-Target", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Content-Sha256", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Algorithm")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Algorithm", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Signature")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Signature", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-SignedHeaders", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Credential")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Credential", valid_604007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604009: Call_GetMLTaskRun_603997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_604009.validator(path, query, header, formData, body)
  let scheme = call_604009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604009.url(scheme.get, call_604009.host, call_604009.base,
                         call_604009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604009, url, valid)

proc call*(call_604010: Call_GetMLTaskRun_603997; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_604011 = newJObject()
  if body != nil:
    body_604011 = body
  result = call_604010.call(nil, nil, nil, nil, body_604011)

var getMLTaskRun* = Call_GetMLTaskRun_603997(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_603998, base: "/", url: url_GetMLTaskRun_603999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_604012 = ref object of OpenApiRestCall_602466
proc url_GetMLTaskRuns_604014(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRuns_604013(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604015 = query.getOrDefault("NextToken")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "NextToken", valid_604015
  var valid_604016 = query.getOrDefault("MaxResults")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "MaxResults", valid_604016
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604017 = header.getOrDefault("X-Amz-Date")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Date", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Security-Token")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Security-Token", valid_604018
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604019 = header.getOrDefault("X-Amz-Target")
  valid_604019 = validateParameter(valid_604019, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_604019 != nil:
    section.add "X-Amz-Target", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Content-Sha256", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Algorithm")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Algorithm", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Signature")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Signature", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-SignedHeaders", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Credential")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Credential", valid_604024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604026: Call_GetMLTaskRuns_604012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_604026.validator(path, query, header, formData, body)
  let scheme = call_604026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604026.url(scheme.get, call_604026.host, call_604026.base,
                         call_604026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604026, url, valid)

proc call*(call_604027: Call_GetMLTaskRuns_604012; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604028 = newJObject()
  var body_604029 = newJObject()
  add(query_604028, "NextToken", newJString(NextToken))
  if body != nil:
    body_604029 = body
  add(query_604028, "MaxResults", newJString(MaxResults))
  result = call_604027.call(nil, query_604028, nil, nil, body_604029)

var getMLTaskRuns* = Call_GetMLTaskRuns_604012(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_604013, base: "/", url: url_GetMLTaskRuns_604014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_604030 = ref object of OpenApiRestCall_602466
proc url_GetMLTransform_604032(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransform_604031(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604033 = header.getOrDefault("X-Amz-Date")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Date", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Security-Token")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Security-Token", valid_604034
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604035 = header.getOrDefault("X-Amz-Target")
  valid_604035 = validateParameter(valid_604035, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_604035 != nil:
    section.add "X-Amz-Target", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Content-Sha256", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Algorithm")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Algorithm", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Signature")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Signature", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-SignedHeaders", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Credential")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Credential", valid_604040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604042: Call_GetMLTransform_604030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_604042.validator(path, query, header, formData, body)
  let scheme = call_604042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604042.url(scheme.get, call_604042.host, call_604042.base,
                         call_604042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604042, url, valid)

proc call*(call_604043: Call_GetMLTransform_604030; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_604044 = newJObject()
  if body != nil:
    body_604044 = body
  result = call_604043.call(nil, nil, nil, nil, body_604044)

var getMLTransform* = Call_GetMLTransform_604030(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_604031, base: "/", url: url_GetMLTransform_604032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_604045 = ref object of OpenApiRestCall_602466
proc url_GetMLTransforms_604047(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransforms_604046(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604048 = query.getOrDefault("NextToken")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "NextToken", valid_604048
  var valid_604049 = query.getOrDefault("MaxResults")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "MaxResults", valid_604049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604050 = header.getOrDefault("X-Amz-Date")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Date", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Security-Token")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Security-Token", valid_604051
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604052 = header.getOrDefault("X-Amz-Target")
  valid_604052 = validateParameter(valid_604052, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_604052 != nil:
    section.add "X-Amz-Target", valid_604052
  var valid_604053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-Content-Sha256", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Algorithm")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Algorithm", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Signature")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Signature", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-SignedHeaders", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Credential")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Credential", valid_604057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604059: Call_GetMLTransforms_604045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_604059.validator(path, query, header, formData, body)
  let scheme = call_604059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604059.url(scheme.get, call_604059.host, call_604059.base,
                         call_604059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604059, url, valid)

proc call*(call_604060: Call_GetMLTransforms_604045; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604061 = newJObject()
  var body_604062 = newJObject()
  add(query_604061, "NextToken", newJString(NextToken))
  if body != nil:
    body_604062 = body
  add(query_604061, "MaxResults", newJString(MaxResults))
  result = call_604060.call(nil, query_604061, nil, nil, body_604062)

var getMLTransforms* = Call_GetMLTransforms_604045(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_604046, base: "/", url: url_GetMLTransforms_604047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_604063 = ref object of OpenApiRestCall_602466
proc url_GetMapping_604065(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMapping_604064(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates mappings.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604066 = header.getOrDefault("X-Amz-Date")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Date", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Security-Token")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Security-Token", valid_604067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604068 = header.getOrDefault("X-Amz-Target")
  valid_604068 = validateParameter(valid_604068, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_604068 != nil:
    section.add "X-Amz-Target", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Content-Sha256", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Algorithm")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Algorithm", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Signature")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Signature", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-SignedHeaders", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Credential")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Credential", valid_604073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604075: Call_GetMapping_604063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_604075.validator(path, query, header, formData, body)
  let scheme = call_604075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604075.url(scheme.get, call_604075.host, call_604075.base,
                         call_604075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604075, url, valid)

proc call*(call_604076: Call_GetMapping_604063; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_604077 = newJObject()
  if body != nil:
    body_604077 = body
  result = call_604076.call(nil, nil, nil, nil, body_604077)

var getMapping* = Call_GetMapping_604063(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_604064,
                                      base: "/", url: url_GetMapping_604065,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_604078 = ref object of OpenApiRestCall_602466
proc url_GetPartition_604080(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartition_604079(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604081 = header.getOrDefault("X-Amz-Date")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Date", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Security-Token")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Security-Token", valid_604082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604083 = header.getOrDefault("X-Amz-Target")
  valid_604083 = validateParameter(valid_604083, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_604083 != nil:
    section.add "X-Amz-Target", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Content-Sha256", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Algorithm")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Algorithm", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Signature")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Signature", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-SignedHeaders", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Credential")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Credential", valid_604088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604090: Call_GetPartition_604078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_604090.validator(path, query, header, formData, body)
  let scheme = call_604090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604090.url(scheme.get, call_604090.host, call_604090.base,
                         call_604090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604090, url, valid)

proc call*(call_604091: Call_GetPartition_604078; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_604092 = newJObject()
  if body != nil:
    body_604092 = body
  result = call_604091.call(nil, nil, nil, nil, body_604092)

var getPartition* = Call_GetPartition_604078(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_604079, base: "/", url: url_GetPartition_604080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_604093 = ref object of OpenApiRestCall_602466
proc url_GetPartitions_604095(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartitions_604094(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the partitions in a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604096 = query.getOrDefault("NextToken")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "NextToken", valid_604096
  var valid_604097 = query.getOrDefault("MaxResults")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "MaxResults", valid_604097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604098 = header.getOrDefault("X-Amz-Date")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Date", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Security-Token")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Security-Token", valid_604099
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604100 = header.getOrDefault("X-Amz-Target")
  valid_604100 = validateParameter(valid_604100, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_604100 != nil:
    section.add "X-Amz-Target", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Content-Sha256", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Algorithm")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Algorithm", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Signature")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Signature", valid_604103
  var valid_604104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "X-Amz-SignedHeaders", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Credential")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Credential", valid_604105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604107: Call_GetPartitions_604093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_604107.validator(path, query, header, formData, body)
  let scheme = call_604107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604107.url(scheme.get, call_604107.host, call_604107.base,
                         call_604107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604107, url, valid)

proc call*(call_604108: Call_GetPartitions_604093; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604109 = newJObject()
  var body_604110 = newJObject()
  add(query_604109, "NextToken", newJString(NextToken))
  if body != nil:
    body_604110 = body
  add(query_604109, "MaxResults", newJString(MaxResults))
  result = call_604108.call(nil, query_604109, nil, nil, body_604110)

var getPartitions* = Call_GetPartitions_604093(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_604094, base: "/", url: url_GetPartitions_604095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_604111 = ref object of OpenApiRestCall_602466
proc url_GetPlan_604113(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPlan_604112(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets code to perform a specified mapping.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604114 = header.getOrDefault("X-Amz-Date")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Date", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Security-Token")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Security-Token", valid_604115
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604116 = header.getOrDefault("X-Amz-Target")
  valid_604116 = validateParameter(valid_604116, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_604116 != nil:
    section.add "X-Amz-Target", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Content-Sha256", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Algorithm")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Algorithm", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-Signature")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Signature", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-SignedHeaders", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Credential")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Credential", valid_604121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604123: Call_GetPlan_604111; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_604123.validator(path, query, header, formData, body)
  let scheme = call_604123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604123.url(scheme.get, call_604123.host, call_604123.base,
                         call_604123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604123, url, valid)

proc call*(call_604124: Call_GetPlan_604111; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_604125 = newJObject()
  if body != nil:
    body_604125 = body
  result = call_604124.call(nil, nil, nil, nil, body_604125)

var getPlan* = Call_GetPlan_604111(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_604112, base: "/",
                                url: url_GetPlan_604113,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_604126 = ref object of OpenApiRestCall_602466
proc url_GetResourcePolicy_604128(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourcePolicy_604127(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a specified resource policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604129 = header.getOrDefault("X-Amz-Date")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Date", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Security-Token")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Security-Token", valid_604130
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604131 = header.getOrDefault("X-Amz-Target")
  valid_604131 = validateParameter(valid_604131, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_604131 != nil:
    section.add "X-Amz-Target", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Content-Sha256", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-Algorithm")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-Algorithm", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-Signature")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-Signature", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-SignedHeaders", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Credential")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Credential", valid_604136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604138: Call_GetResourcePolicy_604126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_604138.validator(path, query, header, formData, body)
  let scheme = call_604138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604138.url(scheme.get, call_604138.host, call_604138.base,
                         call_604138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604138, url, valid)

proc call*(call_604139: Call_GetResourcePolicy_604126; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_604140 = newJObject()
  if body != nil:
    body_604140 = body
  result = call_604139.call(nil, nil, nil, nil, body_604140)

var getResourcePolicy* = Call_GetResourcePolicy_604126(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_604127, base: "/",
    url: url_GetResourcePolicy_604128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_604141 = ref object of OpenApiRestCall_602466
proc url_GetSecurityConfiguration_604143(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfiguration_604142(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified security configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604144 = header.getOrDefault("X-Amz-Date")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Date", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Security-Token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Security-Token", valid_604145
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604146 = header.getOrDefault("X-Amz-Target")
  valid_604146 = validateParameter(valid_604146, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_604146 != nil:
    section.add "X-Amz-Target", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Content-Sha256", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Algorithm")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Algorithm", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-Signature")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Signature", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-SignedHeaders", valid_604150
  var valid_604151 = header.getOrDefault("X-Amz-Credential")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-Credential", valid_604151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604153: Call_GetSecurityConfiguration_604141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_604153.validator(path, query, header, formData, body)
  let scheme = call_604153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604153.url(scheme.get, call_604153.host, call_604153.base,
                         call_604153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604153, url, valid)

proc call*(call_604154: Call_GetSecurityConfiguration_604141; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_604155 = newJObject()
  if body != nil:
    body_604155 = body
  result = call_604154.call(nil, nil, nil, nil, body_604155)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_604141(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_604142, base: "/",
    url: url_GetSecurityConfiguration_604143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_604156 = ref object of OpenApiRestCall_602466
proc url_GetSecurityConfigurations_604158(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfigurations_604157(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of all security configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604159 = query.getOrDefault("NextToken")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "NextToken", valid_604159
  var valid_604160 = query.getOrDefault("MaxResults")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "MaxResults", valid_604160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604161 = header.getOrDefault("X-Amz-Date")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Date", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Security-Token")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Security-Token", valid_604162
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604163 = header.getOrDefault("X-Amz-Target")
  valid_604163 = validateParameter(valid_604163, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_604163 != nil:
    section.add "X-Amz-Target", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Content-Sha256", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Algorithm")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Algorithm", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Signature")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Signature", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-SignedHeaders", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Credential")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Credential", valid_604168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604170: Call_GetSecurityConfigurations_604156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_604170.validator(path, query, header, formData, body)
  let scheme = call_604170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604170.url(scheme.get, call_604170.host, call_604170.base,
                         call_604170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604170, url, valid)

proc call*(call_604171: Call_GetSecurityConfigurations_604156; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604172 = newJObject()
  var body_604173 = newJObject()
  add(query_604172, "NextToken", newJString(NextToken))
  if body != nil:
    body_604173 = body
  add(query_604172, "MaxResults", newJString(MaxResults))
  result = call_604171.call(nil, query_604172, nil, nil, body_604173)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_604156(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_604157, base: "/",
    url: url_GetSecurityConfigurations_604158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_604174 = ref object of OpenApiRestCall_602466
proc url_GetTable_604176(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTable_604175(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604177 = header.getOrDefault("X-Amz-Date")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Date", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Security-Token")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Security-Token", valid_604178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604179 = header.getOrDefault("X-Amz-Target")
  valid_604179 = validateParameter(valid_604179, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_604179 != nil:
    section.add "X-Amz-Target", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Content-Sha256", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Algorithm")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Algorithm", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Signature")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Signature", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-SignedHeaders", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-Credential")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Credential", valid_604184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604186: Call_GetTable_604174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_604186.validator(path, query, header, formData, body)
  let scheme = call_604186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604186.url(scheme.get, call_604186.host, call_604186.base,
                         call_604186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604186, url, valid)

proc call*(call_604187: Call_GetTable_604174; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_604188 = newJObject()
  if body != nil:
    body_604188 = body
  result = call_604187.call(nil, nil, nil, nil, body_604188)

var getTable* = Call_GetTable_604174(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_604175, base: "/",
                                  url: url_GetTable_604176,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_604189 = ref object of OpenApiRestCall_602466
proc url_GetTableVersion_604191(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersion_604190(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a specified version of a table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604192 = header.getOrDefault("X-Amz-Date")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Date", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Security-Token")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Security-Token", valid_604193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604194 = header.getOrDefault("X-Amz-Target")
  valid_604194 = validateParameter(valid_604194, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_604194 != nil:
    section.add "X-Amz-Target", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Content-Sha256", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Algorithm")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Algorithm", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Signature")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Signature", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-SignedHeaders", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Credential")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Credential", valid_604199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604201: Call_GetTableVersion_604189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_604201.validator(path, query, header, formData, body)
  let scheme = call_604201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604201.url(scheme.get, call_604201.host, call_604201.base,
                         call_604201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604201, url, valid)

proc call*(call_604202: Call_GetTableVersion_604189; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_604203 = newJObject()
  if body != nil:
    body_604203 = body
  result = call_604202.call(nil, nil, nil, nil, body_604203)

var getTableVersion* = Call_GetTableVersion_604189(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_604190, base: "/", url: url_GetTableVersion_604191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_604204 = ref object of OpenApiRestCall_602466
proc url_GetTableVersions_604206(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersions_604205(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604207 = query.getOrDefault("NextToken")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "NextToken", valid_604207
  var valid_604208 = query.getOrDefault("MaxResults")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "MaxResults", valid_604208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604209 = header.getOrDefault("X-Amz-Date")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-Date", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Security-Token")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Security-Token", valid_604210
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604211 = header.getOrDefault("X-Amz-Target")
  valid_604211 = validateParameter(valid_604211, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_604211 != nil:
    section.add "X-Amz-Target", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Content-Sha256", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Algorithm")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Algorithm", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Signature")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Signature", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-SignedHeaders", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Credential")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Credential", valid_604216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604218: Call_GetTableVersions_604204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_604218.validator(path, query, header, formData, body)
  let scheme = call_604218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604218.url(scheme.get, call_604218.host, call_604218.base,
                         call_604218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604218, url, valid)

proc call*(call_604219: Call_GetTableVersions_604204; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604220 = newJObject()
  var body_604221 = newJObject()
  add(query_604220, "NextToken", newJString(NextToken))
  if body != nil:
    body_604221 = body
  add(query_604220, "MaxResults", newJString(MaxResults))
  result = call_604219.call(nil, query_604220, nil, nil, body_604221)

var getTableVersions* = Call_GetTableVersions_604204(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_604205, base: "/",
    url: url_GetTableVersions_604206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_604222 = ref object of OpenApiRestCall_602466
proc url_GetTables_604224(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTables_604223(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604225 = query.getOrDefault("NextToken")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "NextToken", valid_604225
  var valid_604226 = query.getOrDefault("MaxResults")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "MaxResults", valid_604226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604227 = header.getOrDefault("X-Amz-Date")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Date", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Security-Token")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Security-Token", valid_604228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604229 = header.getOrDefault("X-Amz-Target")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_604229 != nil:
    section.add "X-Amz-Target", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Content-Sha256", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Algorithm")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Algorithm", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Signature")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Signature", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-SignedHeaders", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Credential")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Credential", valid_604234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604236: Call_GetTables_604222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_604236.validator(path, query, header, formData, body)
  let scheme = call_604236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604236.url(scheme.get, call_604236.host, call_604236.base,
                         call_604236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604236, url, valid)

proc call*(call_604237: Call_GetTables_604222; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604238 = newJObject()
  var body_604239 = newJObject()
  add(query_604238, "NextToken", newJString(NextToken))
  if body != nil:
    body_604239 = body
  add(query_604238, "MaxResults", newJString(MaxResults))
  result = call_604237.call(nil, query_604238, nil, nil, body_604239)

var getTables* = Call_GetTables_604222(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_604223,
                                    base: "/", url: url_GetTables_604224,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_604240 = ref object of OpenApiRestCall_602466
proc url_GetTags_604242(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTags_604241(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of tags associated with a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604243 = header.getOrDefault("X-Amz-Date")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-Date", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Security-Token")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Security-Token", valid_604244
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604245 = header.getOrDefault("X-Amz-Target")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_604245 != nil:
    section.add "X-Amz-Target", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Content-Sha256", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Algorithm")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Algorithm", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Signature")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Signature", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-SignedHeaders", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Credential")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Credential", valid_604250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604252: Call_GetTags_604240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_604252.validator(path, query, header, formData, body)
  let scheme = call_604252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604252.url(scheme.get, call_604252.host, call_604252.base,
                         call_604252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604252, url, valid)

proc call*(call_604253: Call_GetTags_604240; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_604254 = newJObject()
  if body != nil:
    body_604254 = body
  result = call_604253.call(nil, nil, nil, nil, body_604254)

var getTags* = Call_GetTags_604240(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_604241, base: "/",
                                url: url_GetTags_604242,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_604255 = ref object of OpenApiRestCall_602466
proc url_GetTrigger_604257(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTrigger_604256(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a trigger.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604258 = header.getOrDefault("X-Amz-Date")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-Date", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Security-Token")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Security-Token", valid_604259
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604260 = header.getOrDefault("X-Amz-Target")
  valid_604260 = validateParameter(valid_604260, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_604260 != nil:
    section.add "X-Amz-Target", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Content-Sha256", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Algorithm")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Algorithm", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Signature")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Signature", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-SignedHeaders", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Credential")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Credential", valid_604265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604267: Call_GetTrigger_604255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_604267.validator(path, query, header, formData, body)
  let scheme = call_604267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604267.url(scheme.get, call_604267.host, call_604267.base,
                         call_604267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604267, url, valid)

proc call*(call_604268: Call_GetTrigger_604255; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_604269 = newJObject()
  if body != nil:
    body_604269 = body
  result = call_604268.call(nil, nil, nil, nil, body_604269)

var getTrigger* = Call_GetTrigger_604255(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_604256,
                                      base: "/", url: url_GetTrigger_604257,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_604270 = ref object of OpenApiRestCall_602466
proc url_GetTriggers_604272(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTriggers_604271(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the triggers associated with a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604273 = query.getOrDefault("NextToken")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "NextToken", valid_604273
  var valid_604274 = query.getOrDefault("MaxResults")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "MaxResults", valid_604274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604275 = header.getOrDefault("X-Amz-Date")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Date", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-Security-Token")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-Security-Token", valid_604276
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604277 = header.getOrDefault("X-Amz-Target")
  valid_604277 = validateParameter(valid_604277, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_604277 != nil:
    section.add "X-Amz-Target", valid_604277
  var valid_604278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Content-Sha256", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Algorithm")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Algorithm", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Signature")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Signature", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-SignedHeaders", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Credential")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Credential", valid_604282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604284: Call_GetTriggers_604270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_604284.validator(path, query, header, formData, body)
  let scheme = call_604284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604284.url(scheme.get, call_604284.host, call_604284.base,
                         call_604284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604284, url, valid)

proc call*(call_604285: Call_GetTriggers_604270; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604286 = newJObject()
  var body_604287 = newJObject()
  add(query_604286, "NextToken", newJString(NextToken))
  if body != nil:
    body_604287 = body
  add(query_604286, "MaxResults", newJString(MaxResults))
  result = call_604285.call(nil, query_604286, nil, nil, body_604287)

var getTriggers* = Call_GetTriggers_604270(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_604271,
                                        base: "/", url: url_GetTriggers_604272,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_604288 = ref object of OpenApiRestCall_602466
proc url_GetUserDefinedFunction_604290(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunction_604289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified function definition from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604291 = header.getOrDefault("X-Amz-Date")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-Date", valid_604291
  var valid_604292 = header.getOrDefault("X-Amz-Security-Token")
  valid_604292 = validateParameter(valid_604292, JString, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "X-Amz-Security-Token", valid_604292
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604293 = header.getOrDefault("X-Amz-Target")
  valid_604293 = validateParameter(valid_604293, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_604293 != nil:
    section.add "X-Amz-Target", valid_604293
  var valid_604294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "X-Amz-Content-Sha256", valid_604294
  var valid_604295 = header.getOrDefault("X-Amz-Algorithm")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "X-Amz-Algorithm", valid_604295
  var valid_604296 = header.getOrDefault("X-Amz-Signature")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Signature", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-SignedHeaders", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Credential")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Credential", valid_604298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604300: Call_GetUserDefinedFunction_604288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_604300.validator(path, query, header, formData, body)
  let scheme = call_604300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604300.url(scheme.get, call_604300.host, call_604300.base,
                         call_604300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604300, url, valid)

proc call*(call_604301: Call_GetUserDefinedFunction_604288; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_604302 = newJObject()
  if body != nil:
    body_604302 = body
  result = call_604301.call(nil, nil, nil, nil, body_604302)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_604288(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_604289, base: "/",
    url: url_GetUserDefinedFunction_604290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_604303 = ref object of OpenApiRestCall_602466
proc url_GetUserDefinedFunctions_604305(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunctions_604304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604306 = query.getOrDefault("NextToken")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "NextToken", valid_604306
  var valid_604307 = query.getOrDefault("MaxResults")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "MaxResults", valid_604307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604308 = header.getOrDefault("X-Amz-Date")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-Date", valid_604308
  var valid_604309 = header.getOrDefault("X-Amz-Security-Token")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Security-Token", valid_604309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604310 = header.getOrDefault("X-Amz-Target")
  valid_604310 = validateParameter(valid_604310, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_604310 != nil:
    section.add "X-Amz-Target", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-Content-Sha256", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Algorithm")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Algorithm", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Signature")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Signature", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-SignedHeaders", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Credential")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Credential", valid_604315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604317: Call_GetUserDefinedFunctions_604303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_604317.validator(path, query, header, formData, body)
  let scheme = call_604317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604317.url(scheme.get, call_604317.host, call_604317.base,
                         call_604317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604317, url, valid)

proc call*(call_604318: Call_GetUserDefinedFunctions_604303; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604319 = newJObject()
  var body_604320 = newJObject()
  add(query_604319, "NextToken", newJString(NextToken))
  if body != nil:
    body_604320 = body
  add(query_604319, "MaxResults", newJString(MaxResults))
  result = call_604318.call(nil, query_604319, nil, nil, body_604320)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_604303(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_604304, base: "/",
    url: url_GetUserDefinedFunctions_604305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_604321 = ref object of OpenApiRestCall_602466
proc url_GetWorkflow_604323(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflow_604322(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves resource metadata for a workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604324 = header.getOrDefault("X-Amz-Date")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Date", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Security-Token")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Security-Token", valid_604325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604326 = header.getOrDefault("X-Amz-Target")
  valid_604326 = validateParameter(valid_604326, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_604326 != nil:
    section.add "X-Amz-Target", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Content-Sha256", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-Algorithm")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Algorithm", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-Signature")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Signature", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-SignedHeaders", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Credential")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Credential", valid_604331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604333: Call_GetWorkflow_604321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_604333.validator(path, query, header, formData, body)
  let scheme = call_604333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604333.url(scheme.get, call_604333.host, call_604333.base,
                         call_604333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604333, url, valid)

proc call*(call_604334: Call_GetWorkflow_604321; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_604335 = newJObject()
  if body != nil:
    body_604335 = body
  result = call_604334.call(nil, nil, nil, nil, body_604335)

var getWorkflow* = Call_GetWorkflow_604321(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_604322,
                                        base: "/", url: url_GetWorkflow_604323,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_604336 = ref object of OpenApiRestCall_602466
proc url_GetWorkflowRun_604338(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRun_604337(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given workflow run. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604339 = header.getOrDefault("X-Amz-Date")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "X-Amz-Date", valid_604339
  var valid_604340 = header.getOrDefault("X-Amz-Security-Token")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "X-Amz-Security-Token", valid_604340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604341 = header.getOrDefault("X-Amz-Target")
  valid_604341 = validateParameter(valid_604341, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_604341 != nil:
    section.add "X-Amz-Target", valid_604341
  var valid_604342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-Content-Sha256", valid_604342
  var valid_604343 = header.getOrDefault("X-Amz-Algorithm")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Algorithm", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-Signature")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-Signature", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-SignedHeaders", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Credential")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Credential", valid_604346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604348: Call_GetWorkflowRun_604336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_604348.validator(path, query, header, formData, body)
  let scheme = call_604348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604348.url(scheme.get, call_604348.host, call_604348.base,
                         call_604348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604348, url, valid)

proc call*(call_604349: Call_GetWorkflowRun_604336; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_604350 = newJObject()
  if body != nil:
    body_604350 = body
  result = call_604349.call(nil, nil, nil, nil, body_604350)

var getWorkflowRun* = Call_GetWorkflowRun_604336(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_604337, base: "/", url: url_GetWorkflowRun_604338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_604351 = ref object of OpenApiRestCall_602466
proc url_GetWorkflowRunProperties_604353(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRunProperties_604352(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the workflow run properties which were set during the run.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604354 = header.getOrDefault("X-Amz-Date")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Date", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Security-Token")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Security-Token", valid_604355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604356 = header.getOrDefault("X-Amz-Target")
  valid_604356 = validateParameter(valid_604356, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_604356 != nil:
    section.add "X-Amz-Target", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Content-Sha256", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Algorithm")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Algorithm", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Signature")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Signature", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-SignedHeaders", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Credential")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Credential", valid_604361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604363: Call_GetWorkflowRunProperties_604351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_604363.validator(path, query, header, formData, body)
  let scheme = call_604363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604363.url(scheme.get, call_604363.host, call_604363.base,
                         call_604363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604363, url, valid)

proc call*(call_604364: Call_GetWorkflowRunProperties_604351; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_604365 = newJObject()
  if body != nil:
    body_604365 = body
  result = call_604364.call(nil, nil, nil, nil, body_604365)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_604351(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_604352, base: "/",
    url: url_GetWorkflowRunProperties_604353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_604366 = ref object of OpenApiRestCall_602466
proc url_GetWorkflowRuns_604368(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRuns_604367(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604369 = query.getOrDefault("NextToken")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "NextToken", valid_604369
  var valid_604370 = query.getOrDefault("MaxResults")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "MaxResults", valid_604370
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604371 = header.getOrDefault("X-Amz-Date")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Date", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Security-Token")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Security-Token", valid_604372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604373 = header.getOrDefault("X-Amz-Target")
  valid_604373 = validateParameter(valid_604373, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_604373 != nil:
    section.add "X-Amz-Target", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-Content-Sha256", valid_604374
  var valid_604375 = header.getOrDefault("X-Amz-Algorithm")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Algorithm", valid_604375
  var valid_604376 = header.getOrDefault("X-Amz-Signature")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Signature", valid_604376
  var valid_604377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "X-Amz-SignedHeaders", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Credential")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Credential", valid_604378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604380: Call_GetWorkflowRuns_604366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_604380.validator(path, query, header, formData, body)
  let scheme = call_604380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604380.url(scheme.get, call_604380.host, call_604380.base,
                         call_604380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604380, url, valid)

proc call*(call_604381: Call_GetWorkflowRuns_604366; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604382 = newJObject()
  var body_604383 = newJObject()
  add(query_604382, "NextToken", newJString(NextToken))
  if body != nil:
    body_604383 = body
  add(query_604382, "MaxResults", newJString(MaxResults))
  result = call_604381.call(nil, query_604382, nil, nil, body_604383)

var getWorkflowRuns* = Call_GetWorkflowRuns_604366(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_604367, base: "/", url: url_GetWorkflowRuns_604368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_604384 = ref object of OpenApiRestCall_602466
proc url_ImportCatalogToGlue_604386(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCatalogToGlue_604385(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604387 = header.getOrDefault("X-Amz-Date")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Date", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Security-Token")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Security-Token", valid_604388
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604389 = header.getOrDefault("X-Amz-Target")
  valid_604389 = validateParameter(valid_604389, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_604389 != nil:
    section.add "X-Amz-Target", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Content-Sha256", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Algorithm")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Algorithm", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Signature")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Signature", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-SignedHeaders", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Credential")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Credential", valid_604394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604396: Call_ImportCatalogToGlue_604384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_604396.validator(path, query, header, formData, body)
  let scheme = call_604396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604396.url(scheme.get, call_604396.host, call_604396.base,
                         call_604396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604396, url, valid)

proc call*(call_604397: Call_ImportCatalogToGlue_604384; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_604398 = newJObject()
  if body != nil:
    body_604398 = body
  result = call_604397.call(nil, nil, nil, nil, body_604398)

var importCatalogToGlue* = Call_ImportCatalogToGlue_604384(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_604385, base: "/",
    url: url_ImportCatalogToGlue_604386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_604399 = ref object of OpenApiRestCall_602466
proc url_ListCrawlers_604401(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCrawlers_604400(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604402 = query.getOrDefault("NextToken")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "NextToken", valid_604402
  var valid_604403 = query.getOrDefault("MaxResults")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "MaxResults", valid_604403
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604404 = header.getOrDefault("X-Amz-Date")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Date", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Security-Token")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Security-Token", valid_604405
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604406 = header.getOrDefault("X-Amz-Target")
  valid_604406 = validateParameter(valid_604406, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_604406 != nil:
    section.add "X-Amz-Target", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Content-Sha256", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Algorithm")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Algorithm", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Signature")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Signature", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-SignedHeaders", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-Credential")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Credential", valid_604411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604413: Call_ListCrawlers_604399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_604413.validator(path, query, header, formData, body)
  let scheme = call_604413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604413.url(scheme.get, call_604413.host, call_604413.base,
                         call_604413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604413, url, valid)

proc call*(call_604414: Call_ListCrawlers_604399; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604415 = newJObject()
  var body_604416 = newJObject()
  add(query_604415, "NextToken", newJString(NextToken))
  if body != nil:
    body_604416 = body
  add(query_604415, "MaxResults", newJString(MaxResults))
  result = call_604414.call(nil, query_604415, nil, nil, body_604416)

var listCrawlers* = Call_ListCrawlers_604399(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_604400, base: "/", url: url_ListCrawlers_604401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_604417 = ref object of OpenApiRestCall_602466
proc url_ListDevEndpoints_604419(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevEndpoints_604418(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604420 = query.getOrDefault("NextToken")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "NextToken", valid_604420
  var valid_604421 = query.getOrDefault("MaxResults")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "MaxResults", valid_604421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604422 = header.getOrDefault("X-Amz-Date")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "X-Amz-Date", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-Security-Token")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Security-Token", valid_604423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604424 = header.getOrDefault("X-Amz-Target")
  valid_604424 = validateParameter(valid_604424, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_604424 != nil:
    section.add "X-Amz-Target", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Content-Sha256", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Algorithm")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Algorithm", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Signature")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Signature", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-SignedHeaders", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-Credential")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Credential", valid_604429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604431: Call_ListDevEndpoints_604417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_604431.validator(path, query, header, formData, body)
  let scheme = call_604431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604431.url(scheme.get, call_604431.host, call_604431.base,
                         call_604431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604431, url, valid)

proc call*(call_604432: Call_ListDevEndpoints_604417; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604433 = newJObject()
  var body_604434 = newJObject()
  add(query_604433, "NextToken", newJString(NextToken))
  if body != nil:
    body_604434 = body
  add(query_604433, "MaxResults", newJString(MaxResults))
  result = call_604432.call(nil, query_604433, nil, nil, body_604434)

var listDevEndpoints* = Call_ListDevEndpoints_604417(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_604418, base: "/",
    url: url_ListDevEndpoints_604419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_604435 = ref object of OpenApiRestCall_602466
proc url_ListJobs_604437(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_604436(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604438 = query.getOrDefault("NextToken")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "NextToken", valid_604438
  var valid_604439 = query.getOrDefault("MaxResults")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "MaxResults", valid_604439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604440 = header.getOrDefault("X-Amz-Date")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Date", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Security-Token")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Security-Token", valid_604441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604442 = header.getOrDefault("X-Amz-Target")
  valid_604442 = validateParameter(valid_604442, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_604442 != nil:
    section.add "X-Amz-Target", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Content-Sha256", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Algorithm")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Algorithm", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Signature")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Signature", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-SignedHeaders", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Credential")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Credential", valid_604447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604449: Call_ListJobs_604435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_604449.validator(path, query, header, formData, body)
  let scheme = call_604449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604449.url(scheme.get, call_604449.host, call_604449.base,
                         call_604449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604449, url, valid)

proc call*(call_604450: Call_ListJobs_604435; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604451 = newJObject()
  var body_604452 = newJObject()
  add(query_604451, "NextToken", newJString(NextToken))
  if body != nil:
    body_604452 = body
  add(query_604451, "MaxResults", newJString(MaxResults))
  result = call_604450.call(nil, query_604451, nil, nil, body_604452)

var listJobs* = Call_ListJobs_604435(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_604436, base: "/",
                                  url: url_ListJobs_604437,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_604453 = ref object of OpenApiRestCall_602466
proc url_ListTriggers_604455(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTriggers_604454(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604456 = query.getOrDefault("NextToken")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "NextToken", valid_604456
  var valid_604457 = query.getOrDefault("MaxResults")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "MaxResults", valid_604457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604458 = header.getOrDefault("X-Amz-Date")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Date", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-Security-Token")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-Security-Token", valid_604459
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604460 = header.getOrDefault("X-Amz-Target")
  valid_604460 = validateParameter(valid_604460, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_604460 != nil:
    section.add "X-Amz-Target", valid_604460
  var valid_604461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-Content-Sha256", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Algorithm")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Algorithm", valid_604462
  var valid_604463 = header.getOrDefault("X-Amz-Signature")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Signature", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-SignedHeaders", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Credential")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Credential", valid_604465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604467: Call_ListTriggers_604453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_604467.validator(path, query, header, formData, body)
  let scheme = call_604467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604467.url(scheme.get, call_604467.host, call_604467.base,
                         call_604467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604467, url, valid)

proc call*(call_604468: Call_ListTriggers_604453; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604469 = newJObject()
  var body_604470 = newJObject()
  add(query_604469, "NextToken", newJString(NextToken))
  if body != nil:
    body_604470 = body
  add(query_604469, "MaxResults", newJString(MaxResults))
  result = call_604468.call(nil, query_604469, nil, nil, body_604470)

var listTriggers* = Call_ListTriggers_604453(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_604454, base: "/", url: url_ListTriggers_604455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_604471 = ref object of OpenApiRestCall_602466
proc url_ListWorkflows_604473(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkflows_604472(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists names of workflows created in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604474 = query.getOrDefault("NextToken")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "NextToken", valid_604474
  var valid_604475 = query.getOrDefault("MaxResults")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "MaxResults", valid_604475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604476 = header.getOrDefault("X-Amz-Date")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "X-Amz-Date", valid_604476
  var valid_604477 = header.getOrDefault("X-Amz-Security-Token")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Security-Token", valid_604477
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604478 = header.getOrDefault("X-Amz-Target")
  valid_604478 = validateParameter(valid_604478, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_604478 != nil:
    section.add "X-Amz-Target", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Content-Sha256", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Algorithm")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Algorithm", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Signature")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Signature", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-SignedHeaders", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Credential")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Credential", valid_604483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604485: Call_ListWorkflows_604471; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_604485.validator(path, query, header, formData, body)
  let scheme = call_604485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604485.url(scheme.get, call_604485.host, call_604485.base,
                         call_604485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604485, url, valid)

proc call*(call_604486: Call_ListWorkflows_604471; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604487 = newJObject()
  var body_604488 = newJObject()
  add(query_604487, "NextToken", newJString(NextToken))
  if body != nil:
    body_604488 = body
  add(query_604487, "MaxResults", newJString(MaxResults))
  result = call_604486.call(nil, query_604487, nil, nil, body_604488)

var listWorkflows* = Call_ListWorkflows_604471(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_604472, base: "/", url: url_ListWorkflows_604473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_604489 = ref object of OpenApiRestCall_602466
proc url_PutDataCatalogEncryptionSettings_604491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_604490(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604492 = header.getOrDefault("X-Amz-Date")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Date", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Security-Token")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Security-Token", valid_604493
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604494 = header.getOrDefault("X-Amz-Target")
  valid_604494 = validateParameter(valid_604494, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_604494 != nil:
    section.add "X-Amz-Target", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Content-Sha256", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Algorithm")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Algorithm", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Signature")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Signature", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-SignedHeaders", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Credential")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Credential", valid_604499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604501: Call_PutDataCatalogEncryptionSettings_604489;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_604501.validator(path, query, header, formData, body)
  let scheme = call_604501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604501.url(scheme.get, call_604501.host, call_604501.base,
                         call_604501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604501, url, valid)

proc call*(call_604502: Call_PutDataCatalogEncryptionSettings_604489;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_604503 = newJObject()
  if body != nil:
    body_604503 = body
  result = call_604502.call(nil, nil, nil, nil, body_604503)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_604489(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_604490, base: "/",
    url: url_PutDataCatalogEncryptionSettings_604491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_604504 = ref object of OpenApiRestCall_602466
proc url_PutResourcePolicy_604506(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResourcePolicy_604505(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Sets the Data Catalog resource policy for access control.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604507 = header.getOrDefault("X-Amz-Date")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Date", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Security-Token")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Security-Token", valid_604508
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604509 = header.getOrDefault("X-Amz-Target")
  valid_604509 = validateParameter(valid_604509, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_604509 != nil:
    section.add "X-Amz-Target", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Content-Sha256", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Algorithm")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Algorithm", valid_604511
  var valid_604512 = header.getOrDefault("X-Amz-Signature")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "X-Amz-Signature", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-SignedHeaders", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Credential")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Credential", valid_604514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604516: Call_PutResourcePolicy_604504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_604516.validator(path, query, header, formData, body)
  let scheme = call_604516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604516.url(scheme.get, call_604516.host, call_604516.base,
                         call_604516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604516, url, valid)

proc call*(call_604517: Call_PutResourcePolicy_604504; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_604518 = newJObject()
  if body != nil:
    body_604518 = body
  result = call_604517.call(nil, nil, nil, nil, body_604518)

var putResourcePolicy* = Call_PutResourcePolicy_604504(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_604505, base: "/",
    url: url_PutResourcePolicy_604506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_604519 = ref object of OpenApiRestCall_602466
proc url_PutWorkflowRunProperties_604521(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutWorkflowRunProperties_604520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604522 = header.getOrDefault("X-Amz-Date")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Date", valid_604522
  var valid_604523 = header.getOrDefault("X-Amz-Security-Token")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-Security-Token", valid_604523
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604524 = header.getOrDefault("X-Amz-Target")
  valid_604524 = validateParameter(valid_604524, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_604524 != nil:
    section.add "X-Amz-Target", valid_604524
  var valid_604525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Content-Sha256", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Algorithm")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Algorithm", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-Signature")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-Signature", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-SignedHeaders", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Credential")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Credential", valid_604529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604531: Call_PutWorkflowRunProperties_604519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_604531.validator(path, query, header, formData, body)
  let scheme = call_604531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604531.url(scheme.get, call_604531.host, call_604531.base,
                         call_604531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604531, url, valid)

proc call*(call_604532: Call_PutWorkflowRunProperties_604519; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_604533 = newJObject()
  if body != nil:
    body_604533 = body
  result = call_604532.call(nil, nil, nil, nil, body_604533)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_604519(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_604520, base: "/",
    url: url_PutWorkflowRunProperties_604521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_604534 = ref object of OpenApiRestCall_602466
proc url_ResetJobBookmark_604536(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetJobBookmark_604535(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets a bookmark entry.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604537 = header.getOrDefault("X-Amz-Date")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Date", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Security-Token")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Security-Token", valid_604538
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604539 = header.getOrDefault("X-Amz-Target")
  valid_604539 = validateParameter(valid_604539, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_604539 != nil:
    section.add "X-Amz-Target", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Content-Sha256", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Algorithm")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Algorithm", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Signature")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Signature", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-SignedHeaders", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Credential")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Credential", valid_604544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604546: Call_ResetJobBookmark_604534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_604546.validator(path, query, header, formData, body)
  let scheme = call_604546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604546.url(scheme.get, call_604546.host, call_604546.base,
                         call_604546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604546, url, valid)

proc call*(call_604547: Call_ResetJobBookmark_604534; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_604548 = newJObject()
  if body != nil:
    body_604548 = body
  result = call_604547.call(nil, nil, nil, nil, body_604548)

var resetJobBookmark* = Call_ResetJobBookmark_604534(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_604535, base: "/",
    url: url_ResetJobBookmark_604536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_604549 = ref object of OpenApiRestCall_602466
proc url_SearchTables_604551(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchTables_604550(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604552 = query.getOrDefault("NextToken")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "NextToken", valid_604552
  var valid_604553 = query.getOrDefault("MaxResults")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "MaxResults", valid_604553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604554 = header.getOrDefault("X-Amz-Date")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "X-Amz-Date", valid_604554
  var valid_604555 = header.getOrDefault("X-Amz-Security-Token")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Security-Token", valid_604555
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604556 = header.getOrDefault("X-Amz-Target")
  valid_604556 = validateParameter(valid_604556, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_604556 != nil:
    section.add "X-Amz-Target", valid_604556
  var valid_604557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-Content-Sha256", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Algorithm")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Algorithm", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Signature")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Signature", valid_604559
  var valid_604560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-SignedHeaders", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-Credential")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Credential", valid_604561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604563: Call_SearchTables_604549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_604563.validator(path, query, header, formData, body)
  let scheme = call_604563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604563.url(scheme.get, call_604563.host, call_604563.base,
                         call_604563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604563, url, valid)

proc call*(call_604564: Call_SearchTables_604549; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604565 = newJObject()
  var body_604566 = newJObject()
  add(query_604565, "NextToken", newJString(NextToken))
  if body != nil:
    body_604566 = body
  add(query_604565, "MaxResults", newJString(MaxResults))
  result = call_604564.call(nil, query_604565, nil, nil, body_604566)

var searchTables* = Call_SearchTables_604549(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_604550, base: "/", url: url_SearchTables_604551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_604567 = ref object of OpenApiRestCall_602466
proc url_StartCrawler_604569(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawler_604568(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604570 = header.getOrDefault("X-Amz-Date")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "X-Amz-Date", valid_604570
  var valid_604571 = header.getOrDefault("X-Amz-Security-Token")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "X-Amz-Security-Token", valid_604571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604572 = header.getOrDefault("X-Amz-Target")
  valid_604572 = validateParameter(valid_604572, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_604572 != nil:
    section.add "X-Amz-Target", valid_604572
  var valid_604573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Content-Sha256", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Algorithm")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Algorithm", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Signature")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Signature", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-SignedHeaders", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Credential")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Credential", valid_604577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604579: Call_StartCrawler_604567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_604579.validator(path, query, header, formData, body)
  let scheme = call_604579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604579.url(scheme.get, call_604579.host, call_604579.base,
                         call_604579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604579, url, valid)

proc call*(call_604580: Call_StartCrawler_604567; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_604581 = newJObject()
  if body != nil:
    body_604581 = body
  result = call_604580.call(nil, nil, nil, nil, body_604581)

var startCrawler* = Call_StartCrawler_604567(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_604568, base: "/", url: url_StartCrawler_604569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_604582 = ref object of OpenApiRestCall_602466
proc url_StartCrawlerSchedule_604584(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawlerSchedule_604583(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604585 = header.getOrDefault("X-Amz-Date")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Date", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Security-Token")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Security-Token", valid_604586
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604587 = header.getOrDefault("X-Amz-Target")
  valid_604587 = validateParameter(valid_604587, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_604587 != nil:
    section.add "X-Amz-Target", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Content-Sha256", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Algorithm")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Algorithm", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Signature")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Signature", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-SignedHeaders", valid_604591
  var valid_604592 = header.getOrDefault("X-Amz-Credential")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "X-Amz-Credential", valid_604592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604594: Call_StartCrawlerSchedule_604582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_604594.validator(path, query, header, formData, body)
  let scheme = call_604594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604594.url(scheme.get, call_604594.host, call_604594.base,
                         call_604594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604594, url, valid)

proc call*(call_604595: Call_StartCrawlerSchedule_604582; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_604596 = newJObject()
  if body != nil:
    body_604596 = body
  result = call_604595.call(nil, nil, nil, nil, body_604596)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_604582(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_604583, base: "/",
    url: url_StartCrawlerSchedule_604584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_604597 = ref object of OpenApiRestCall_602466
proc url_StartExportLabelsTaskRun_604599(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartExportLabelsTaskRun_604598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604600 = header.getOrDefault("X-Amz-Date")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Date", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-Security-Token")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-Security-Token", valid_604601
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604602 = header.getOrDefault("X-Amz-Target")
  valid_604602 = validateParameter(valid_604602, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_604602 != nil:
    section.add "X-Amz-Target", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Content-Sha256", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Algorithm")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Algorithm", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Signature")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Signature", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-SignedHeaders", valid_604606
  var valid_604607 = header.getOrDefault("X-Amz-Credential")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-Credential", valid_604607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604609: Call_StartExportLabelsTaskRun_604597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_604609.validator(path, query, header, formData, body)
  let scheme = call_604609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604609.url(scheme.get, call_604609.host, call_604609.base,
                         call_604609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604609, url, valid)

proc call*(call_604610: Call_StartExportLabelsTaskRun_604597; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_604611 = newJObject()
  if body != nil:
    body_604611 = body
  result = call_604610.call(nil, nil, nil, nil, body_604611)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_604597(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_604598, base: "/",
    url: url_StartExportLabelsTaskRun_604599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_604612 = ref object of OpenApiRestCall_602466
proc url_StartImportLabelsTaskRun_604614(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImportLabelsTaskRun_604613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604615 = header.getOrDefault("X-Amz-Date")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "X-Amz-Date", valid_604615
  var valid_604616 = header.getOrDefault("X-Amz-Security-Token")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "X-Amz-Security-Token", valid_604616
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604617 = header.getOrDefault("X-Amz-Target")
  valid_604617 = validateParameter(valid_604617, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_604617 != nil:
    section.add "X-Amz-Target", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Content-Sha256", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-Algorithm")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Algorithm", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Signature")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Signature", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-SignedHeaders", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-Credential")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Credential", valid_604622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604624: Call_StartImportLabelsTaskRun_604612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_604624.validator(path, query, header, formData, body)
  let scheme = call_604624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604624.url(scheme.get, call_604624.host, call_604624.base,
                         call_604624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604624, url, valid)

proc call*(call_604625: Call_StartImportLabelsTaskRun_604612; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_604626 = newJObject()
  if body != nil:
    body_604626 = body
  result = call_604625.call(nil, nil, nil, nil, body_604626)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_604612(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_604613, base: "/",
    url: url_StartImportLabelsTaskRun_604614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_604627 = ref object of OpenApiRestCall_602466
proc url_StartJobRun_604629(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartJobRun_604628(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job run using a job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604630 = header.getOrDefault("X-Amz-Date")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Date", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-Security-Token")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Security-Token", valid_604631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604632 = header.getOrDefault("X-Amz-Target")
  valid_604632 = validateParameter(valid_604632, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_604632 != nil:
    section.add "X-Amz-Target", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Content-Sha256", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-Algorithm")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Algorithm", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Signature")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Signature", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-SignedHeaders", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Credential")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Credential", valid_604637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604639: Call_StartJobRun_604627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_604639.validator(path, query, header, formData, body)
  let scheme = call_604639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604639.url(scheme.get, call_604639.host, call_604639.base,
                         call_604639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604639, url, valid)

proc call*(call_604640: Call_StartJobRun_604627; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_604641 = newJObject()
  if body != nil:
    body_604641 = body
  result = call_604640.call(nil, nil, nil, nil, body_604641)

var startJobRun* = Call_StartJobRun_604627(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_604628,
                                        base: "/", url: url_StartJobRun_604629,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_604642 = ref object of OpenApiRestCall_602466
proc url_StartMLEvaluationTaskRun_604644(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLEvaluationTaskRun_604643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604645 = header.getOrDefault("X-Amz-Date")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Date", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-Security-Token")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-Security-Token", valid_604646
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604647 = header.getOrDefault("X-Amz-Target")
  valid_604647 = validateParameter(valid_604647, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_604647 != nil:
    section.add "X-Amz-Target", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Content-Sha256", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Algorithm")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Algorithm", valid_604649
  var valid_604650 = header.getOrDefault("X-Amz-Signature")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Signature", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-SignedHeaders", valid_604651
  var valid_604652 = header.getOrDefault("X-Amz-Credential")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Credential", valid_604652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604654: Call_StartMLEvaluationTaskRun_604642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_604654.validator(path, query, header, formData, body)
  let scheme = call_604654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604654.url(scheme.get, call_604654.host, call_604654.base,
                         call_604654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604654, url, valid)

proc call*(call_604655: Call_StartMLEvaluationTaskRun_604642; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_604656 = newJObject()
  if body != nil:
    body_604656 = body
  result = call_604655.call(nil, nil, nil, nil, body_604656)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_604642(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_604643, base: "/",
    url: url_StartMLEvaluationTaskRun_604644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_604657 = ref object of OpenApiRestCall_602466
proc url_StartMLLabelingSetGenerationTaskRun_604659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_604658(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604660 = header.getOrDefault("X-Amz-Date")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Date", valid_604660
  var valid_604661 = header.getOrDefault("X-Amz-Security-Token")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "X-Amz-Security-Token", valid_604661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604662 = header.getOrDefault("X-Amz-Target")
  valid_604662 = validateParameter(valid_604662, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_604662 != nil:
    section.add "X-Amz-Target", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Content-Sha256", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Algorithm")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Algorithm", valid_604664
  var valid_604665 = header.getOrDefault("X-Amz-Signature")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Signature", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-SignedHeaders", valid_604666
  var valid_604667 = header.getOrDefault("X-Amz-Credential")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "X-Amz-Credential", valid_604667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604669: Call_StartMLLabelingSetGenerationTaskRun_604657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_604669.validator(path, query, header, formData, body)
  let scheme = call_604669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604669.url(scheme.get, call_604669.host, call_604669.base,
                         call_604669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604669, url, valid)

proc call*(call_604670: Call_StartMLLabelingSetGenerationTaskRun_604657;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_604671 = newJObject()
  if body != nil:
    body_604671 = body
  result = call_604670.call(nil, nil, nil, nil, body_604671)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_604657(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_604658, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_604659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_604672 = ref object of OpenApiRestCall_602466
proc url_StartTrigger_604674(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTrigger_604673(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604675 = header.getOrDefault("X-Amz-Date")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Date", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Security-Token")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Security-Token", valid_604676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604677 = header.getOrDefault("X-Amz-Target")
  valid_604677 = validateParameter(valid_604677, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_604677 != nil:
    section.add "X-Amz-Target", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Content-Sha256", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Algorithm")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Algorithm", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-Signature")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-Signature", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-SignedHeaders", valid_604681
  var valid_604682 = header.getOrDefault("X-Amz-Credential")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-Credential", valid_604682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604684: Call_StartTrigger_604672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_604684.validator(path, query, header, formData, body)
  let scheme = call_604684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604684.url(scheme.get, call_604684.host, call_604684.base,
                         call_604684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604684, url, valid)

proc call*(call_604685: Call_StartTrigger_604672; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_604686 = newJObject()
  if body != nil:
    body_604686 = body
  result = call_604685.call(nil, nil, nil, nil, body_604686)

var startTrigger* = Call_StartTrigger_604672(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_604673, base: "/", url: url_StartTrigger_604674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_604687 = ref object of OpenApiRestCall_602466
proc url_StartWorkflowRun_604689(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkflowRun_604688(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Starts a new run of the specified workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604690 = header.getOrDefault("X-Amz-Date")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Date", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Security-Token")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Security-Token", valid_604691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604692 = header.getOrDefault("X-Amz-Target")
  valid_604692 = validateParameter(valid_604692, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_604692 != nil:
    section.add "X-Amz-Target", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Content-Sha256", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Algorithm")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Algorithm", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Signature")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Signature", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-SignedHeaders", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Credential")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Credential", valid_604697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604699: Call_StartWorkflowRun_604687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_604699.validator(path, query, header, formData, body)
  let scheme = call_604699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604699.url(scheme.get, call_604699.host, call_604699.base,
                         call_604699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604699, url, valid)

proc call*(call_604700: Call_StartWorkflowRun_604687; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_604701 = newJObject()
  if body != nil:
    body_604701 = body
  result = call_604700.call(nil, nil, nil, nil, body_604701)

var startWorkflowRun* = Call_StartWorkflowRun_604687(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_604688, base: "/",
    url: url_StartWorkflowRun_604689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_604702 = ref object of OpenApiRestCall_602466
proc url_StopCrawler_604704(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawler_604703(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## If the specified crawler is running, stops the crawl.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604705 = header.getOrDefault("X-Amz-Date")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "X-Amz-Date", valid_604705
  var valid_604706 = header.getOrDefault("X-Amz-Security-Token")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Security-Token", valid_604706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604707 = header.getOrDefault("X-Amz-Target")
  valid_604707 = validateParameter(valid_604707, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_604707 != nil:
    section.add "X-Amz-Target", valid_604707
  var valid_604708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Content-Sha256", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Algorithm")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Algorithm", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Signature")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Signature", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-SignedHeaders", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Credential")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Credential", valid_604712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604714: Call_StopCrawler_604702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_604714.validator(path, query, header, formData, body)
  let scheme = call_604714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604714.url(scheme.get, call_604714.host, call_604714.base,
                         call_604714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604714, url, valid)

proc call*(call_604715: Call_StopCrawler_604702; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_604716 = newJObject()
  if body != nil:
    body_604716 = body
  result = call_604715.call(nil, nil, nil, nil, body_604716)

var stopCrawler* = Call_StopCrawler_604702(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_604703,
                                        base: "/", url: url_StopCrawler_604704,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_604717 = ref object of OpenApiRestCall_602466
proc url_StopCrawlerSchedule_604719(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawlerSchedule_604718(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604720 = header.getOrDefault("X-Amz-Date")
  valid_604720 = validateParameter(valid_604720, JString, required = false,
                                 default = nil)
  if valid_604720 != nil:
    section.add "X-Amz-Date", valid_604720
  var valid_604721 = header.getOrDefault("X-Amz-Security-Token")
  valid_604721 = validateParameter(valid_604721, JString, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "X-Amz-Security-Token", valid_604721
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604722 = header.getOrDefault("X-Amz-Target")
  valid_604722 = validateParameter(valid_604722, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_604722 != nil:
    section.add "X-Amz-Target", valid_604722
  var valid_604723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Content-Sha256", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Algorithm")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Algorithm", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Signature")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Signature", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-SignedHeaders", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Credential")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Credential", valid_604727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604729: Call_StopCrawlerSchedule_604717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_604729.validator(path, query, header, formData, body)
  let scheme = call_604729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604729.url(scheme.get, call_604729.host, call_604729.base,
                         call_604729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604729, url, valid)

proc call*(call_604730: Call_StopCrawlerSchedule_604717; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_604731 = newJObject()
  if body != nil:
    body_604731 = body
  result = call_604730.call(nil, nil, nil, nil, body_604731)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_604717(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_604718, base: "/",
    url: url_StopCrawlerSchedule_604719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_604732 = ref object of OpenApiRestCall_602466
proc url_StopTrigger_604734(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrigger_604733(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a specified trigger.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604735 = header.getOrDefault("X-Amz-Date")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Date", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Security-Token")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Security-Token", valid_604736
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604737 = header.getOrDefault("X-Amz-Target")
  valid_604737 = validateParameter(valid_604737, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_604737 != nil:
    section.add "X-Amz-Target", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Content-Sha256", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Algorithm")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Algorithm", valid_604739
  var valid_604740 = header.getOrDefault("X-Amz-Signature")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "X-Amz-Signature", valid_604740
  var valid_604741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "X-Amz-SignedHeaders", valid_604741
  var valid_604742 = header.getOrDefault("X-Amz-Credential")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "X-Amz-Credential", valid_604742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604744: Call_StopTrigger_604732; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_604744.validator(path, query, header, formData, body)
  let scheme = call_604744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604744.url(scheme.get, call_604744.host, call_604744.base,
                         call_604744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604744, url, valid)

proc call*(call_604745: Call_StopTrigger_604732; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_604746 = newJObject()
  if body != nil:
    body_604746 = body
  result = call_604745.call(nil, nil, nil, nil, body_604746)

var stopTrigger* = Call_StopTrigger_604732(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_604733,
                                        base: "/", url: url_StopTrigger_604734,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604747 = ref object of OpenApiRestCall_602466
proc url_TagResource_604749(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_604748(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604750 = header.getOrDefault("X-Amz-Date")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-Date", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Security-Token")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Security-Token", valid_604751
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604752 = header.getOrDefault("X-Amz-Target")
  valid_604752 = validateParameter(valid_604752, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_604752 != nil:
    section.add "X-Amz-Target", valid_604752
  var valid_604753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Content-Sha256", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Algorithm")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Algorithm", valid_604754
  var valid_604755 = header.getOrDefault("X-Amz-Signature")
  valid_604755 = validateParameter(valid_604755, JString, required = false,
                                 default = nil)
  if valid_604755 != nil:
    section.add "X-Amz-Signature", valid_604755
  var valid_604756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604756 = validateParameter(valid_604756, JString, required = false,
                                 default = nil)
  if valid_604756 != nil:
    section.add "X-Amz-SignedHeaders", valid_604756
  var valid_604757 = header.getOrDefault("X-Amz-Credential")
  valid_604757 = validateParameter(valid_604757, JString, required = false,
                                 default = nil)
  if valid_604757 != nil:
    section.add "X-Amz-Credential", valid_604757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604759: Call_TagResource_604747; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_604759.validator(path, query, header, formData, body)
  let scheme = call_604759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604759.url(scheme.get, call_604759.host, call_604759.base,
                         call_604759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604759, url, valid)

proc call*(call_604760: Call_TagResource_604747; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_604761 = newJObject()
  if body != nil:
    body_604761 = body
  result = call_604760.call(nil, nil, nil, nil, body_604761)

var tagResource* = Call_TagResource_604747(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_604748,
                                        base: "/", url: url_TagResource_604749,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604762 = ref object of OpenApiRestCall_602466
proc url_UntagResource_604764(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_604763(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604765 = header.getOrDefault("X-Amz-Date")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-Date", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Security-Token")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Security-Token", valid_604766
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604767 = header.getOrDefault("X-Amz-Target")
  valid_604767 = validateParameter(valid_604767, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_604767 != nil:
    section.add "X-Amz-Target", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Content-Sha256", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Algorithm")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Algorithm", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-Signature")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-Signature", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-SignedHeaders", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-Credential")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-Credential", valid_604772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604774: Call_UntagResource_604762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_604774.validator(path, query, header, formData, body)
  let scheme = call_604774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604774.url(scheme.get, call_604774.host, call_604774.base,
                         call_604774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604774, url, valid)

proc call*(call_604775: Call_UntagResource_604762; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_604776 = newJObject()
  if body != nil:
    body_604776 = body
  result = call_604775.call(nil, nil, nil, nil, body_604776)

var untagResource* = Call_UntagResource_604762(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_604763, base: "/", url: url_UntagResource_604764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_604777 = ref object of OpenApiRestCall_602466
proc url_UpdateClassifier_604779(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateClassifier_604778(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604780 = header.getOrDefault("X-Amz-Date")
  valid_604780 = validateParameter(valid_604780, JString, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "X-Amz-Date", valid_604780
  var valid_604781 = header.getOrDefault("X-Amz-Security-Token")
  valid_604781 = validateParameter(valid_604781, JString, required = false,
                                 default = nil)
  if valid_604781 != nil:
    section.add "X-Amz-Security-Token", valid_604781
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604782 = header.getOrDefault("X-Amz-Target")
  valid_604782 = validateParameter(valid_604782, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_604782 != nil:
    section.add "X-Amz-Target", valid_604782
  var valid_604783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Content-Sha256", valid_604783
  var valid_604784 = header.getOrDefault("X-Amz-Algorithm")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "X-Amz-Algorithm", valid_604784
  var valid_604785 = header.getOrDefault("X-Amz-Signature")
  valid_604785 = validateParameter(valid_604785, JString, required = false,
                                 default = nil)
  if valid_604785 != nil:
    section.add "X-Amz-Signature", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-SignedHeaders", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-Credential")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-Credential", valid_604787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604789: Call_UpdateClassifier_604777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_604789.validator(path, query, header, formData, body)
  let scheme = call_604789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604789.url(scheme.get, call_604789.host, call_604789.base,
                         call_604789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604789, url, valid)

proc call*(call_604790: Call_UpdateClassifier_604777; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_604791 = newJObject()
  if body != nil:
    body_604791 = body
  result = call_604790.call(nil, nil, nil, nil, body_604791)

var updateClassifier* = Call_UpdateClassifier_604777(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_604778, base: "/",
    url: url_UpdateClassifier_604779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_604792 = ref object of OpenApiRestCall_602466
proc url_UpdateConnection_604794(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConnection_604793(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a connection definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604795 = header.getOrDefault("X-Amz-Date")
  valid_604795 = validateParameter(valid_604795, JString, required = false,
                                 default = nil)
  if valid_604795 != nil:
    section.add "X-Amz-Date", valid_604795
  var valid_604796 = header.getOrDefault("X-Amz-Security-Token")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "X-Amz-Security-Token", valid_604796
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604797 = header.getOrDefault("X-Amz-Target")
  valid_604797 = validateParameter(valid_604797, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_604797 != nil:
    section.add "X-Amz-Target", valid_604797
  var valid_604798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-Content-Sha256", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-Algorithm")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-Algorithm", valid_604799
  var valid_604800 = header.getOrDefault("X-Amz-Signature")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "X-Amz-Signature", valid_604800
  var valid_604801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604801 = validateParameter(valid_604801, JString, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "X-Amz-SignedHeaders", valid_604801
  var valid_604802 = header.getOrDefault("X-Amz-Credential")
  valid_604802 = validateParameter(valid_604802, JString, required = false,
                                 default = nil)
  if valid_604802 != nil:
    section.add "X-Amz-Credential", valid_604802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604804: Call_UpdateConnection_604792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_604804.validator(path, query, header, formData, body)
  let scheme = call_604804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604804.url(scheme.get, call_604804.host, call_604804.base,
                         call_604804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604804, url, valid)

proc call*(call_604805: Call_UpdateConnection_604792; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_604806 = newJObject()
  if body != nil:
    body_604806 = body
  result = call_604805.call(nil, nil, nil, nil, body_604806)

var updateConnection* = Call_UpdateConnection_604792(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_604793, base: "/",
    url: url_UpdateConnection_604794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_604807 = ref object of OpenApiRestCall_602466
proc url_UpdateCrawler_604809(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawler_604808(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604810 = header.getOrDefault("X-Amz-Date")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Date", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Security-Token")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Security-Token", valid_604811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604812 = header.getOrDefault("X-Amz-Target")
  valid_604812 = validateParameter(valid_604812, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_604812 != nil:
    section.add "X-Amz-Target", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Content-Sha256", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-Algorithm")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-Algorithm", valid_604814
  var valid_604815 = header.getOrDefault("X-Amz-Signature")
  valid_604815 = validateParameter(valid_604815, JString, required = false,
                                 default = nil)
  if valid_604815 != nil:
    section.add "X-Amz-Signature", valid_604815
  var valid_604816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604816 = validateParameter(valid_604816, JString, required = false,
                                 default = nil)
  if valid_604816 != nil:
    section.add "X-Amz-SignedHeaders", valid_604816
  var valid_604817 = header.getOrDefault("X-Amz-Credential")
  valid_604817 = validateParameter(valid_604817, JString, required = false,
                                 default = nil)
  if valid_604817 != nil:
    section.add "X-Amz-Credential", valid_604817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604819: Call_UpdateCrawler_604807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_604819.validator(path, query, header, formData, body)
  let scheme = call_604819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604819.url(scheme.get, call_604819.host, call_604819.base,
                         call_604819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604819, url, valid)

proc call*(call_604820: Call_UpdateCrawler_604807; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_604821 = newJObject()
  if body != nil:
    body_604821 = body
  result = call_604820.call(nil, nil, nil, nil, body_604821)

var updateCrawler* = Call_UpdateCrawler_604807(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_604808, base: "/", url: url_UpdateCrawler_604809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_604822 = ref object of OpenApiRestCall_602466
proc url_UpdateCrawlerSchedule_604824(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawlerSchedule_604823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604825 = header.getOrDefault("X-Amz-Date")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Date", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Security-Token")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Security-Token", valid_604826
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604827 = header.getOrDefault("X-Amz-Target")
  valid_604827 = validateParameter(valid_604827, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_604827 != nil:
    section.add "X-Amz-Target", valid_604827
  var valid_604828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Content-Sha256", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-Algorithm")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-Algorithm", valid_604829
  var valid_604830 = header.getOrDefault("X-Amz-Signature")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "X-Amz-Signature", valid_604830
  var valid_604831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604831 = validateParameter(valid_604831, JString, required = false,
                                 default = nil)
  if valid_604831 != nil:
    section.add "X-Amz-SignedHeaders", valid_604831
  var valid_604832 = header.getOrDefault("X-Amz-Credential")
  valid_604832 = validateParameter(valid_604832, JString, required = false,
                                 default = nil)
  if valid_604832 != nil:
    section.add "X-Amz-Credential", valid_604832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604834: Call_UpdateCrawlerSchedule_604822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_604834.validator(path, query, header, formData, body)
  let scheme = call_604834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604834.url(scheme.get, call_604834.host, call_604834.base,
                         call_604834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604834, url, valid)

proc call*(call_604835: Call_UpdateCrawlerSchedule_604822; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_604836 = newJObject()
  if body != nil:
    body_604836 = body
  result = call_604835.call(nil, nil, nil, nil, body_604836)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_604822(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_604823, base: "/",
    url: url_UpdateCrawlerSchedule_604824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_604837 = ref object of OpenApiRestCall_602466
proc url_UpdateDatabase_604839(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDatabase_604838(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing database definition in a Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604840 = header.getOrDefault("X-Amz-Date")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Date", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Security-Token")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Security-Token", valid_604841
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604842 = header.getOrDefault("X-Amz-Target")
  valid_604842 = validateParameter(valid_604842, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_604842 != nil:
    section.add "X-Amz-Target", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Content-Sha256", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Algorithm")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Algorithm", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Signature")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Signature", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-SignedHeaders", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Credential")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Credential", valid_604847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604849: Call_UpdateDatabase_604837; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_604849.validator(path, query, header, formData, body)
  let scheme = call_604849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604849.url(scheme.get, call_604849.host, call_604849.base,
                         call_604849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604849, url, valid)

proc call*(call_604850: Call_UpdateDatabase_604837; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_604851 = newJObject()
  if body != nil:
    body_604851 = body
  result = call_604850.call(nil, nil, nil, nil, body_604851)

var updateDatabase* = Call_UpdateDatabase_604837(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_604838, base: "/", url: url_UpdateDatabase_604839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_604852 = ref object of OpenApiRestCall_602466
proc url_UpdateDevEndpoint_604854(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevEndpoint_604853(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a specified development endpoint.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604855 = header.getOrDefault("X-Amz-Date")
  valid_604855 = validateParameter(valid_604855, JString, required = false,
                                 default = nil)
  if valid_604855 != nil:
    section.add "X-Amz-Date", valid_604855
  var valid_604856 = header.getOrDefault("X-Amz-Security-Token")
  valid_604856 = validateParameter(valid_604856, JString, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "X-Amz-Security-Token", valid_604856
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604857 = header.getOrDefault("X-Amz-Target")
  valid_604857 = validateParameter(valid_604857, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_604857 != nil:
    section.add "X-Amz-Target", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Content-Sha256", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Algorithm")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Algorithm", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-Signature")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-Signature", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-SignedHeaders", valid_604861
  var valid_604862 = header.getOrDefault("X-Amz-Credential")
  valid_604862 = validateParameter(valid_604862, JString, required = false,
                                 default = nil)
  if valid_604862 != nil:
    section.add "X-Amz-Credential", valid_604862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604864: Call_UpdateDevEndpoint_604852; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_604864.validator(path, query, header, formData, body)
  let scheme = call_604864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604864.url(scheme.get, call_604864.host, call_604864.base,
                         call_604864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604864, url, valid)

proc call*(call_604865: Call_UpdateDevEndpoint_604852; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_604866 = newJObject()
  if body != nil:
    body_604866 = body
  result = call_604865.call(nil, nil, nil, nil, body_604866)

var updateDevEndpoint* = Call_UpdateDevEndpoint_604852(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_604853, base: "/",
    url: url_UpdateDevEndpoint_604854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_604867 = ref object of OpenApiRestCall_602466
proc url_UpdateJob_604869(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJob_604868(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604870 = header.getOrDefault("X-Amz-Date")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "X-Amz-Date", valid_604870
  var valid_604871 = header.getOrDefault("X-Amz-Security-Token")
  valid_604871 = validateParameter(valid_604871, JString, required = false,
                                 default = nil)
  if valid_604871 != nil:
    section.add "X-Amz-Security-Token", valid_604871
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604872 = header.getOrDefault("X-Amz-Target")
  valid_604872 = validateParameter(valid_604872, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_604872 != nil:
    section.add "X-Amz-Target", valid_604872
  var valid_604873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604873 = validateParameter(valid_604873, JString, required = false,
                                 default = nil)
  if valid_604873 != nil:
    section.add "X-Amz-Content-Sha256", valid_604873
  var valid_604874 = header.getOrDefault("X-Amz-Algorithm")
  valid_604874 = validateParameter(valid_604874, JString, required = false,
                                 default = nil)
  if valid_604874 != nil:
    section.add "X-Amz-Algorithm", valid_604874
  var valid_604875 = header.getOrDefault("X-Amz-Signature")
  valid_604875 = validateParameter(valid_604875, JString, required = false,
                                 default = nil)
  if valid_604875 != nil:
    section.add "X-Amz-Signature", valid_604875
  var valid_604876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-SignedHeaders", valid_604876
  var valid_604877 = header.getOrDefault("X-Amz-Credential")
  valid_604877 = validateParameter(valid_604877, JString, required = false,
                                 default = nil)
  if valid_604877 != nil:
    section.add "X-Amz-Credential", valid_604877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604879: Call_UpdateJob_604867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_604879.validator(path, query, header, formData, body)
  let scheme = call_604879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604879.url(scheme.get, call_604879.host, call_604879.base,
                         call_604879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604879, url, valid)

proc call*(call_604880: Call_UpdateJob_604867; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_604881 = newJObject()
  if body != nil:
    body_604881 = body
  result = call_604880.call(nil, nil, nil, nil, body_604881)

var updateJob* = Call_UpdateJob_604867(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_604868,
                                    base: "/", url: url_UpdateJob_604869,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_604882 = ref object of OpenApiRestCall_602466
proc url_UpdateMLTransform_604884(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMLTransform_604883(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604885 = header.getOrDefault("X-Amz-Date")
  valid_604885 = validateParameter(valid_604885, JString, required = false,
                                 default = nil)
  if valid_604885 != nil:
    section.add "X-Amz-Date", valid_604885
  var valid_604886 = header.getOrDefault("X-Amz-Security-Token")
  valid_604886 = validateParameter(valid_604886, JString, required = false,
                                 default = nil)
  if valid_604886 != nil:
    section.add "X-Amz-Security-Token", valid_604886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604887 = header.getOrDefault("X-Amz-Target")
  valid_604887 = validateParameter(valid_604887, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_604887 != nil:
    section.add "X-Amz-Target", valid_604887
  var valid_604888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604888 = validateParameter(valid_604888, JString, required = false,
                                 default = nil)
  if valid_604888 != nil:
    section.add "X-Amz-Content-Sha256", valid_604888
  var valid_604889 = header.getOrDefault("X-Amz-Algorithm")
  valid_604889 = validateParameter(valid_604889, JString, required = false,
                                 default = nil)
  if valid_604889 != nil:
    section.add "X-Amz-Algorithm", valid_604889
  var valid_604890 = header.getOrDefault("X-Amz-Signature")
  valid_604890 = validateParameter(valid_604890, JString, required = false,
                                 default = nil)
  if valid_604890 != nil:
    section.add "X-Amz-Signature", valid_604890
  var valid_604891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604891 = validateParameter(valid_604891, JString, required = false,
                                 default = nil)
  if valid_604891 != nil:
    section.add "X-Amz-SignedHeaders", valid_604891
  var valid_604892 = header.getOrDefault("X-Amz-Credential")
  valid_604892 = validateParameter(valid_604892, JString, required = false,
                                 default = nil)
  if valid_604892 != nil:
    section.add "X-Amz-Credential", valid_604892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604894: Call_UpdateMLTransform_604882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_604894.validator(path, query, header, formData, body)
  let scheme = call_604894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604894.url(scheme.get, call_604894.host, call_604894.base,
                         call_604894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604894, url, valid)

proc call*(call_604895: Call_UpdateMLTransform_604882; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_604896 = newJObject()
  if body != nil:
    body_604896 = body
  result = call_604895.call(nil, nil, nil, nil, body_604896)

var updateMLTransform* = Call_UpdateMLTransform_604882(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_604883, base: "/",
    url: url_UpdateMLTransform_604884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_604897 = ref object of OpenApiRestCall_602466
proc url_UpdatePartition_604899(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePartition_604898(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604900 = header.getOrDefault("X-Amz-Date")
  valid_604900 = validateParameter(valid_604900, JString, required = false,
                                 default = nil)
  if valid_604900 != nil:
    section.add "X-Amz-Date", valid_604900
  var valid_604901 = header.getOrDefault("X-Amz-Security-Token")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "X-Amz-Security-Token", valid_604901
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604902 = header.getOrDefault("X-Amz-Target")
  valid_604902 = validateParameter(valid_604902, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_604902 != nil:
    section.add "X-Amz-Target", valid_604902
  var valid_604903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "X-Amz-Content-Sha256", valid_604903
  var valid_604904 = header.getOrDefault("X-Amz-Algorithm")
  valid_604904 = validateParameter(valid_604904, JString, required = false,
                                 default = nil)
  if valid_604904 != nil:
    section.add "X-Amz-Algorithm", valid_604904
  var valid_604905 = header.getOrDefault("X-Amz-Signature")
  valid_604905 = validateParameter(valid_604905, JString, required = false,
                                 default = nil)
  if valid_604905 != nil:
    section.add "X-Amz-Signature", valid_604905
  var valid_604906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604906 = validateParameter(valid_604906, JString, required = false,
                                 default = nil)
  if valid_604906 != nil:
    section.add "X-Amz-SignedHeaders", valid_604906
  var valid_604907 = header.getOrDefault("X-Amz-Credential")
  valid_604907 = validateParameter(valid_604907, JString, required = false,
                                 default = nil)
  if valid_604907 != nil:
    section.add "X-Amz-Credential", valid_604907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604909: Call_UpdatePartition_604897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_604909.validator(path, query, header, formData, body)
  let scheme = call_604909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604909.url(scheme.get, call_604909.host, call_604909.base,
                         call_604909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604909, url, valid)

proc call*(call_604910: Call_UpdatePartition_604897; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_604911 = newJObject()
  if body != nil:
    body_604911 = body
  result = call_604910.call(nil, nil, nil, nil, body_604911)

var updatePartition* = Call_UpdatePartition_604897(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_604898, base: "/", url: url_UpdatePartition_604899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_604912 = ref object of OpenApiRestCall_602466
proc url_UpdateTable_604914(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTable_604913(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a metadata table in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604915 = header.getOrDefault("X-Amz-Date")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-Date", valid_604915
  var valid_604916 = header.getOrDefault("X-Amz-Security-Token")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "X-Amz-Security-Token", valid_604916
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604917 = header.getOrDefault("X-Amz-Target")
  valid_604917 = validateParameter(valid_604917, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_604917 != nil:
    section.add "X-Amz-Target", valid_604917
  var valid_604918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604918 = validateParameter(valid_604918, JString, required = false,
                                 default = nil)
  if valid_604918 != nil:
    section.add "X-Amz-Content-Sha256", valid_604918
  var valid_604919 = header.getOrDefault("X-Amz-Algorithm")
  valid_604919 = validateParameter(valid_604919, JString, required = false,
                                 default = nil)
  if valid_604919 != nil:
    section.add "X-Amz-Algorithm", valid_604919
  var valid_604920 = header.getOrDefault("X-Amz-Signature")
  valid_604920 = validateParameter(valid_604920, JString, required = false,
                                 default = nil)
  if valid_604920 != nil:
    section.add "X-Amz-Signature", valid_604920
  var valid_604921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604921 = validateParameter(valid_604921, JString, required = false,
                                 default = nil)
  if valid_604921 != nil:
    section.add "X-Amz-SignedHeaders", valid_604921
  var valid_604922 = header.getOrDefault("X-Amz-Credential")
  valid_604922 = validateParameter(valid_604922, JString, required = false,
                                 default = nil)
  if valid_604922 != nil:
    section.add "X-Amz-Credential", valid_604922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604924: Call_UpdateTable_604912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_604924.validator(path, query, header, formData, body)
  let scheme = call_604924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604924.url(scheme.get, call_604924.host, call_604924.base,
                         call_604924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604924, url, valid)

proc call*(call_604925: Call_UpdateTable_604912; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_604926 = newJObject()
  if body != nil:
    body_604926 = body
  result = call_604925.call(nil, nil, nil, nil, body_604926)

var updateTable* = Call_UpdateTable_604912(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_604913,
                                        base: "/", url: url_UpdateTable_604914,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_604927 = ref object of OpenApiRestCall_602466
proc url_UpdateTrigger_604929(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTrigger_604928(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a trigger definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604930 = header.getOrDefault("X-Amz-Date")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Date", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-Security-Token")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Security-Token", valid_604931
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604932 = header.getOrDefault("X-Amz-Target")
  valid_604932 = validateParameter(valid_604932, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_604932 != nil:
    section.add "X-Amz-Target", valid_604932
  var valid_604933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-Content-Sha256", valid_604933
  var valid_604934 = header.getOrDefault("X-Amz-Algorithm")
  valid_604934 = validateParameter(valid_604934, JString, required = false,
                                 default = nil)
  if valid_604934 != nil:
    section.add "X-Amz-Algorithm", valid_604934
  var valid_604935 = header.getOrDefault("X-Amz-Signature")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "X-Amz-Signature", valid_604935
  var valid_604936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604936 = validateParameter(valid_604936, JString, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "X-Amz-SignedHeaders", valid_604936
  var valid_604937 = header.getOrDefault("X-Amz-Credential")
  valid_604937 = validateParameter(valid_604937, JString, required = false,
                                 default = nil)
  if valid_604937 != nil:
    section.add "X-Amz-Credential", valid_604937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604939: Call_UpdateTrigger_604927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_604939.validator(path, query, header, formData, body)
  let scheme = call_604939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604939.url(scheme.get, call_604939.host, call_604939.base,
                         call_604939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604939, url, valid)

proc call*(call_604940: Call_UpdateTrigger_604927; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_604941 = newJObject()
  if body != nil:
    body_604941 = body
  result = call_604940.call(nil, nil, nil, nil, body_604941)

var updateTrigger* = Call_UpdateTrigger_604927(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_604928, base: "/", url: url_UpdateTrigger_604929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_604942 = ref object of OpenApiRestCall_602466
proc url_UpdateUserDefinedFunction_604944(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUserDefinedFunction_604943(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing function definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604945 = header.getOrDefault("X-Amz-Date")
  valid_604945 = validateParameter(valid_604945, JString, required = false,
                                 default = nil)
  if valid_604945 != nil:
    section.add "X-Amz-Date", valid_604945
  var valid_604946 = header.getOrDefault("X-Amz-Security-Token")
  valid_604946 = validateParameter(valid_604946, JString, required = false,
                                 default = nil)
  if valid_604946 != nil:
    section.add "X-Amz-Security-Token", valid_604946
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604947 = header.getOrDefault("X-Amz-Target")
  valid_604947 = validateParameter(valid_604947, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_604947 != nil:
    section.add "X-Amz-Target", valid_604947
  var valid_604948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604948 = validateParameter(valid_604948, JString, required = false,
                                 default = nil)
  if valid_604948 != nil:
    section.add "X-Amz-Content-Sha256", valid_604948
  var valid_604949 = header.getOrDefault("X-Amz-Algorithm")
  valid_604949 = validateParameter(valid_604949, JString, required = false,
                                 default = nil)
  if valid_604949 != nil:
    section.add "X-Amz-Algorithm", valid_604949
  var valid_604950 = header.getOrDefault("X-Amz-Signature")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "X-Amz-Signature", valid_604950
  var valid_604951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "X-Amz-SignedHeaders", valid_604951
  var valid_604952 = header.getOrDefault("X-Amz-Credential")
  valid_604952 = validateParameter(valid_604952, JString, required = false,
                                 default = nil)
  if valid_604952 != nil:
    section.add "X-Amz-Credential", valid_604952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604954: Call_UpdateUserDefinedFunction_604942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_604954.validator(path, query, header, formData, body)
  let scheme = call_604954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604954.url(scheme.get, call_604954.host, call_604954.base,
                         call_604954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604954, url, valid)

proc call*(call_604955: Call_UpdateUserDefinedFunction_604942; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_604956 = newJObject()
  if body != nil:
    body_604956 = body
  result = call_604955.call(nil, nil, nil, nil, body_604956)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_604942(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_604943, base: "/",
    url: url_UpdateUserDefinedFunction_604944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_604957 = ref object of OpenApiRestCall_602466
proc url_UpdateWorkflow_604959(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkflow_604958(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604960 = header.getOrDefault("X-Amz-Date")
  valid_604960 = validateParameter(valid_604960, JString, required = false,
                                 default = nil)
  if valid_604960 != nil:
    section.add "X-Amz-Date", valid_604960
  var valid_604961 = header.getOrDefault("X-Amz-Security-Token")
  valid_604961 = validateParameter(valid_604961, JString, required = false,
                                 default = nil)
  if valid_604961 != nil:
    section.add "X-Amz-Security-Token", valid_604961
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604962 = header.getOrDefault("X-Amz-Target")
  valid_604962 = validateParameter(valid_604962, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_604962 != nil:
    section.add "X-Amz-Target", valid_604962
  var valid_604963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604963 = validateParameter(valid_604963, JString, required = false,
                                 default = nil)
  if valid_604963 != nil:
    section.add "X-Amz-Content-Sha256", valid_604963
  var valid_604964 = header.getOrDefault("X-Amz-Algorithm")
  valid_604964 = validateParameter(valid_604964, JString, required = false,
                                 default = nil)
  if valid_604964 != nil:
    section.add "X-Amz-Algorithm", valid_604964
  var valid_604965 = header.getOrDefault("X-Amz-Signature")
  valid_604965 = validateParameter(valid_604965, JString, required = false,
                                 default = nil)
  if valid_604965 != nil:
    section.add "X-Amz-Signature", valid_604965
  var valid_604966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604966 = validateParameter(valid_604966, JString, required = false,
                                 default = nil)
  if valid_604966 != nil:
    section.add "X-Amz-SignedHeaders", valid_604966
  var valid_604967 = header.getOrDefault("X-Amz-Credential")
  valid_604967 = validateParameter(valid_604967, JString, required = false,
                                 default = nil)
  if valid_604967 != nil:
    section.add "X-Amz-Credential", valid_604967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604969: Call_UpdateWorkflow_604957; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_604969.validator(path, query, header, formData, body)
  let scheme = call_604969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604969.url(scheme.get, call_604969.host, call_604969.base,
                         call_604969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604969, url, valid)

proc call*(call_604970: Call_UpdateWorkflow_604957; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_604971 = newJObject()
  if body != nil:
    body_604971 = body
  result = call_604970.call(nil, nil, nil, nil, body_604971)

var updateWorkflow* = Call_UpdateWorkflow_604957(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_604958, base: "/", url: url_UpdateWorkflow_604959,
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
