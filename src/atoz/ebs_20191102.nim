
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic Block Store
## version: 2019-11-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>You can use the Amazon Elastic Block Store (EBS) direct APIs to directly read the data on your EBS snapshots, and identify the difference between two snapshots. You can view the details of blocks in an EBS snapshot, compare the block difference between two snapshots, and directly access the data in a snapshot. If you’re an independent software vendor (ISV) who offers backup services for EBS, the EBS direct APIs makes it easier and more cost-effective to track incremental changes on your EBS volumes via EBS snapshots. This can be done without having to create new volumes from EBS snapshots, and then use EC2 instances to compare the differences.</p> <p>This API reference provides detailed information about the actions, data types, parameters, and errors of the EBS direct APIs. For more information about the elements that make up the EBS direct APIs, and examples of how to use them effectively, see <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-accessing-snapshot.html">Accessing the Contents of an EBS Snapshot</a>. For more information about how to use the EBS direct APIs, see the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-accessing-snapshots.html">EBS direct APIs User Guide</a>. To view the currently supported AWS Regions and endpoints for the EBS direct APIs, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#ebs_region">AWS Service Endpoints</a> in the <i>AWS General Reference</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ebs/
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ebs.us-west-2.amazonaws.com",
                           "eu-west-2": "ebs.eu-west-2.amazonaws.com", "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ebs.eu-central-1.amazonaws.com",
                           "us-east-2": "ebs.us-east-2.amazonaws.com",
                           "us-east-1": "ebs.us-east-1.amazonaws.com", "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ebs.ap-south-1.amazonaws.com",
                           "eu-north-1": "ebs.eu-north-1.amazonaws.com", "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ebs.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ebs.eu-west-3.amazonaws.com",
                           "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ebs.sa-east-1.amazonaws.com",
                           "eu-west-1": "ebs.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
      "us-west-2": "ebs.us-west-2.amazonaws.com",
      "eu-west-2": "ebs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ebs.eu-central-1.amazonaws.com",
      "us-east-2": "ebs.us-east-2.amazonaws.com",
      "us-east-1": "ebs.us-east-1.amazonaws.com",
      "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ebs.ap-south-1.amazonaws.com",
      "eu-north-1": "ebs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
      "us-west-1": "ebs.us-west-1.amazonaws.com",
      "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ebs.eu-west-3.amazonaws.com",
      "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ebs.sa-east-1.amazonaws.com",
      "eu-west-1": "ebs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ebs"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetSnapshotBlock_605918 = ref object of OpenApiRestCall_605580
proc url_GetSnapshotBlock_605920(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "snapshotId" in path, "`snapshotId` is a required path parameter"
  assert "blockIndex" in path, "`blockIndex` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
               (kind: VariableSegment, value: "snapshotId"),
               (kind: ConstantSegment, value: "/blocks/"),
               (kind: VariableSegment, value: "blockIndex"),
               (kind: ConstantSegment, value: "#blockToken")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSnapshotBlock_605919(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: JInt (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>block index</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `snapshotId` field"
  var valid_606046 = path.getOrDefault("snapshotId")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "snapshotId", valid_606046
  var valid_606047 = path.getOrDefault("blockIndex")
  valid_606047 = validateParameter(valid_606047, JInt, required = true, default = nil)
  if valid_606047 != nil:
    section.add "blockIndex", valid_606047
  result.add "path", section
  ## parameters in `query` object:
  ##   blockToken: JString (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>block token</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `blockToken` field"
  var valid_606048 = query.getOrDefault("blockToken")
  valid_606048 = validateParameter(valid_606048, JString, required = true,
                                 default = nil)
  if valid_606048 != nil:
    section.add "blockToken", valid_606048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606049 = header.getOrDefault("X-Amz-Signature")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Signature", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Content-Sha256", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Date")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Date", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Credential")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Credential", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-Security-Token")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-Security-Token", valid_606053
  var valid_606054 = header.getOrDefault("X-Amz-Algorithm")
  valid_606054 = validateParameter(valid_606054, JString, required = false,
                                 default = nil)
  if valid_606054 != nil:
    section.add "X-Amz-Algorithm", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-SignedHeaders", valid_606055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606078: Call_GetSnapshotBlock_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_606078.validator(path, query, header, formData, body)
  let scheme = call_606078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606078.url(scheme.get, call_606078.host, call_606078.base,
                         call_606078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606078, url, valid)

proc call*(call_606149: Call_GetSnapshotBlock_605918; snapshotId: string;
          blockIndex: int; blockToken: string): Recallable =
  ## getSnapshotBlock
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: int (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>block index</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  ##   blockToken: string (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>block token</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  var path_606150 = newJObject()
  var query_606152 = newJObject()
  add(path_606150, "snapshotId", newJString(snapshotId))
  add(path_606150, "blockIndex", newJInt(blockIndex))
  add(query_606152, "blockToken", newJString(blockToken))
  result = call_606149.call(path_606150, query_606152, nil, nil, nil)

var getSnapshotBlock* = Call_GetSnapshotBlock_605918(name: "getSnapshotBlock",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks/{blockIndex}#blockToken",
    validator: validate_GetSnapshotBlock_605919, base: "/",
    url: url_GetSnapshotBlock_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangedBlocks_606191 = ref object of OpenApiRestCall_605580
proc url_ListChangedBlocks_606193(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "secondSnapshotId" in path,
        "`secondSnapshotId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
               (kind: VariableSegment, value: "secondSnapshotId"),
               (kind: ConstantSegment, value: "/changedblocks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListChangedBlocks_606192(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   secondSnapshotId: JString (required)
  ##                   : The ID of the second snapshot to use for the comparison.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `secondSnapshotId` field"
  var valid_606194 = path.getOrDefault("secondSnapshotId")
  valid_606194 = validateParameter(valid_606194, JString, required = true,
                                 default = nil)
  if valid_606194 != nil:
    section.add "secondSnapshotId", valid_606194
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: JInt
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   firstSnapshotId: JString
  ##                  : The ID of the first snapshot to use for the comparison.
  ##   maxResults: JInt
  ##             : The number of results to return.
  section = newJObject()
  var valid_606195 = query.getOrDefault("MaxResults")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "MaxResults", valid_606195
  var valid_606196 = query.getOrDefault("NextToken")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "NextToken", valid_606196
  var valid_606197 = query.getOrDefault("pageToken")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "pageToken", valid_606197
  var valid_606198 = query.getOrDefault("startingBlockIndex")
  valid_606198 = validateParameter(valid_606198, JInt, required = false, default = nil)
  if valid_606198 != nil:
    section.add "startingBlockIndex", valid_606198
  var valid_606199 = query.getOrDefault("firstSnapshotId")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "firstSnapshotId", valid_606199
  var valid_606200 = query.getOrDefault("maxResults")
  valid_606200 = validateParameter(valid_606200, JInt, required = false, default = nil)
  if valid_606200 != nil:
    section.add "maxResults", valid_606200
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_ListChangedBlocks_606191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_ListChangedBlocks_606191; secondSnapshotId: string;
          MaxResults: string = ""; NextToken: string = ""; pageToken: string = "";
          startingBlockIndex: int = 0; firstSnapshotId: string = ""; maxResults: int = 0): Recallable =
  ## listChangedBlocks
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   secondSnapshotId: string (required)
  ##                   : The ID of the second snapshot to use for the comparison.
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: int
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   firstSnapshotId: string
  ##                  : The ID of the first snapshot to use for the comparison.
  ##   maxResults: int
  ##             : The number of results to return.
  var path_606210 = newJObject()
  var query_606211 = newJObject()
  add(query_606211, "MaxResults", newJString(MaxResults))
  add(query_606211, "NextToken", newJString(NextToken))
  add(path_606210, "secondSnapshotId", newJString(secondSnapshotId))
  add(query_606211, "pageToken", newJString(pageToken))
  add(query_606211, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_606211, "firstSnapshotId", newJString(firstSnapshotId))
  add(query_606211, "maxResults", newJInt(maxResults))
  result = call_606209.call(path_606210, query_606211, nil, nil, nil)

var listChangedBlocks* = Call_ListChangedBlocks_606191(name: "listChangedBlocks",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{secondSnapshotId}/changedblocks",
    validator: validate_ListChangedBlocks_606192, base: "/",
    url: url_ListChangedBlocks_606193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSnapshotBlocks_606212 = ref object of OpenApiRestCall_605580
proc url_ListSnapshotBlocks_606214(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "snapshotId" in path, "`snapshotId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
               (kind: VariableSegment, value: "snapshotId"),
               (kind: ConstantSegment, value: "/blocks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSnapshotBlocks_606213(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
  ##             : The ID of the snapshot from which to get block indexes and block tokens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `snapshotId` field"
  var valid_606215 = path.getOrDefault("snapshotId")
  valid_606215 = validateParameter(valid_606215, JString, required = true,
                                 default = nil)
  if valid_606215 != nil:
    section.add "snapshotId", valid_606215
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: JInt
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   maxResults: JInt
  ##             : The number of results to return.
  section = newJObject()
  var valid_606216 = query.getOrDefault("MaxResults")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "MaxResults", valid_606216
  var valid_606217 = query.getOrDefault("NextToken")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "NextToken", valid_606217
  var valid_606218 = query.getOrDefault("pageToken")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "pageToken", valid_606218
  var valid_606219 = query.getOrDefault("startingBlockIndex")
  valid_606219 = validateParameter(valid_606219, JInt, required = false, default = nil)
  if valid_606219 != nil:
    section.add "startingBlockIndex", valid_606219
  var valid_606220 = query.getOrDefault("maxResults")
  valid_606220 = validateParameter(valid_606220, JInt, required = false, default = nil)
  if valid_606220 != nil:
    section.add "maxResults", valid_606220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606221 = header.getOrDefault("X-Amz-Signature")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Signature", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Content-Sha256", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Date")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Date", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Credential")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Credential", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Security-Token")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Security-Token", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Algorithm")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Algorithm", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-SignedHeaders", valid_606227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606228: Call_ListSnapshotBlocks_606212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_606228.validator(path, query, header, formData, body)
  let scheme = call_606228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606228.url(scheme.get, call_606228.host, call_606228.base,
                         call_606228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606228, url, valid)

proc call*(call_606229: Call_ListSnapshotBlocks_606212; snapshotId: string;
          MaxResults: string = ""; NextToken: string = ""; pageToken: string = "";
          startingBlockIndex: int = 0; maxResults: int = 0): Recallable =
  ## listSnapshotBlocks
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot from which to get block indexes and block tokens.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: int
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   maxResults: int
  ##             : The number of results to return.
  var path_606230 = newJObject()
  var query_606231 = newJObject()
  add(path_606230, "snapshotId", newJString(snapshotId))
  add(query_606231, "MaxResults", newJString(MaxResults))
  add(query_606231, "NextToken", newJString(NextToken))
  add(query_606231, "pageToken", newJString(pageToken))
  add(query_606231, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_606231, "maxResults", newJInt(maxResults))
  result = call_606229.call(path_606230, query_606231, nil, nil, nil)

var listSnapshotBlocks* = Call_ListSnapshotBlocks_606212(
    name: "listSnapshotBlocks", meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks",
    validator: validate_ListSnapshotBlocks_606213, base: "/",
    url: url_ListSnapshotBlocks_606214, schemes: {Scheme.Https, Scheme.Http})
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)